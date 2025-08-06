once this stack is applied, the Azure OpenAI account you provisioned behaves like OpenAI’s public API in all key ways:

Endpoint shape
Requests go to https://<your-resource-name>.openai.azure.com/openai/deployments/<model-deployment>/chat/completions?api-version=2024-02-15-preview
Same JSON request/response format as api.openai.com. Only the hostname and required api-version query-param differ.
Auth model
Instead of bearer keys from OpenAI, you use Azure keys or Azure AD tokens.
Our APIM front-door issues subscription keys so you can keep the experience “bearer-token-only” for callers if desired.
Models & capability parity
You deploy GPT-4o, GPT-3.5-turbo, embeddings, etc. exactly as you would choose models in OpenAI.
Some latest previews appear on OpenAI first and arrive in Azure a few weeks later.
Rate limits & quotas
Controlled by your Azure subscription capacity requests rather than the public OpenAI org limits.
APIM lets you overlay custom per-subscriber quotas or metering.
Enterprise controls in this stack
Private endpoints, CMK encryption, diagnostic logging, and policy guard-rails—things you don’t get from the public OpenAI SaaS.

With the workspace-per-subscriber or loop-module pattern, each subscriber ends up with its own:

Resource group(s)
Spoke VNet and private endpoints
Key Vault + customer-managed key
Azure OpenAI account (and its quota)
Private APIM front-door
That yields clean isolation of data, network, RBAC, and lifecycle: you can destroy or update one subscriber without affecting others.

If you prefer a multi-tenant model (shared OpenAI account, shared APIM, keys per user, etc.) you can still do it by:

Deploying the stack once as a “shared” environment.
Creating an APIM Product for each subscriber, issuing them unique subscription keys, and using APIM policies to enforce per-subscriber quotas and logging.
So the IaC supports both:

Dedicated instance per subscriber (strongest isolation, simplest mental model)
Shared instance with APIM segmentation (lower cost, more operational rules to enforce)
Pick the model that matches your governance and cost requirements.

## Prompt History
Azure OpenAI itself does not persist your prompt / completion bodies for later retrieval—once the request is processed the payload is discarded (other than anonymised telemetry used by Microsoft).

## Security

### No customer-data training
Microsoft contractually commits that prompts, completions, and embeddings from Azure OpenAI are never used to retrain any foundation models, public or private.

Data stays within the region of your resource, encrypted at rest, and is deleted after the request (aside from aggregated, anonymised telemetry).

### Isolation from other tenants
Your traffic runs on dedicated capacity slices; another tenant can’t “poison” or observe your context window.

What you still need to do on your side:

Prompt-injection defence
- Validate / sanitise user input at your application layer.
- Add system-instructions that override malicious user roles.
- If exposing the API to untrusted users, set conservative max-tokens and temperature, and use content-filter endpoints.

Fault-injection / chaos testing
- Because traffic is private-network-only, attackers would have to compromise an internal caller first.
- Use APIM policies to throttle abnormal request rates and reject oversized payloads.
- Enable Azure Monitor alerts on error-rate or latency spikes (already captured by the diagnostic settings).

### Prompt Injection Defence
- Validate / sanitise user input at your application layer.
- Add system-instructions that override malicious user roles.
- If exposing the API to untrusted users, set conservative max-tokens and temperature, and use content-filter endpoints.

#### Below is a practical pattern for “prompt-sanitisation” in Azure API Management.

It lets you block or rewrite prompts that contain disallowed strings before they reach the Azure OpenAI endpoint.

1. Policy logic (XML)
Add an <inbound> policy to the API scope (or Product scope if you want per-subscriber rules).

```xml
<policies>
  <inbound>
    <!-- Parse JSON body -->
    <set-variable name="body"
                  value="@(|context.Request.Body.As<JObject>(preserveContent:true)|)" />

    <!-- Basic example: block if prompt includes forbidden words -->
    <choose>
      <when condition="@( ((string)context.Variables["body"]["messages"][0]["content"])
                           .ToLowerInvariant()
                           .Contains("password") )">
        <return-response>
          <set-status code="400" reason="Bad Request" />
          <set-body>
            {"error":"Prompt contains disallowed content."}
          </set-body>
        </return-response>
      </when>
    </choose>

    <!-- Optionally: strip PII via regex -->
    <set-variable name="sanitisedPrompt"
                  value='@(System.Text.RegularExpressions.Regex
                           .Replace((string)context.Variables["body"]["messages"][0]["content"],
                                    @"[0-9]{3}-[0-9]{2}-[0-9]{4}", "***SSN***"))' />

    <!-- Write the cleaned prompt back into the request -->
    <set-body>@{
      context.Variables["body"]["messages"][0]["content"] =
           context.Variables["sanitisedPrompt"];
      return context.Variables["body"].ToString();
    }</set-body>

    <base />
  </inbound>

  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```

#### What it does

- Reads the JSON request body into body.
- Checks the first message content; if it contains “password” (example), immediately rejects.
- Otherwise uses a regex to scrub US-SSN patterns and rewrites the body.
- Proceeds to the backend (<base />) with the sanitized prompt.

You can expand the logic—call an external DLP service, run a basic LLM filter, etc.

2. Automating via Terraform
In 
modules/api_gateway
, add a policy resource:

```hcl
resource "azurerm_api_management_api_policy" "prompt_sanitize" {
  api_name            = azurerm_api_management_api.openai_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  xml_content         = file("${path.module}/policies/prompt-sanitize.xml")
}
```

Commit the XML snippet to modules/api_gateway/policies/prompt-sanitize.xml (the file shown above).
Optionally parameterise forbidden words or regex patterns via policy <set-variable> with {{subscription-key}}-style templates, or generate the XML with Terraform templatefile() and variables.

3. Testing & rollback
```bash
# Call via APIM with a bad prompt
curl -X POST https://gateway.azure-api.net/openai/...
     -H "Ocp-Apim-Subscription-Key: <key>"
     -H "Content-Type: application/json"
     -d '{"messages":[{"role":"user","content":"my password is 123"}]}'
```

#### → HTTP 400 {"error":"Prompt contains disallowed content."}
Because the policy is applied at API scope, you can disable it quickly in the portal or by setting xml_content = "" and re-applying Terraform.

4. Advanced ideas
- External moderation API – Call Azure Content Safety or your own service inside the policy (<send-request>), and block/modify based on its score.
- Rate-based blocking – Combine with APIM <quota> and <rate-limit> to throttle repeated offences.
- Logging – Add <log-to-eventhub> or <trace> statements for caught violations to feed your SIEM.

That’s all you need to wire automated sanitisation into APIM and keep Azure OpenAI protected from malicious or policy-violating prompts.
