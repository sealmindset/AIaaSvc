# End-to-end provisioning flow
1. AAD account
- Each internal developer already has an Entra ID (Azure AD) user object ID.
- Optionally, your Terraform initial_user_object_ids list can pre-seed a live subscription for those IDs.

2. Sign-in to the APIM Developer Portal
```text
https://apim-ai-internal.<corp>/developer
```
- Choose “Sign in with Microsoft”.
- Portal authenticates the user via AAD and links the portal profile to that object ID.

3. Request a subscription key
- Navigate to the product Internal OpenAI (product ID openai).
- Click Subscribe.
  – If the user was pre-seeded, the product already shows an Active subscription; keys are visible immediately.
  – Otherwise a new subscription is created in Submitted state and an approver (APIM admin) receives an email/portal notification.

4. Approval (built-in workflow)
- APIM admin reviews the request in the Azure portal or Publisher Portal and clicks Approve (or Reject).
- Terraform made the product approval_required = true, so this gate is always enforced.

5. Developer retrieves keys
- Once approved, the subscription state flips to Active and two keys (primaryKey, secondaryKey) become visible in the portal UI or via REST (/subscriptions/{sid}/listSecrets?api-version=).
- The user copies one key.

6. Calling the private OpenAI endpoint
```http
POST https://apim-ai-internal.<corp>/v1/chat/completions
Ocp-Apim-Subscription-Key: <primaryKey>
Content-Type: application/json
```

- Inbound APIM policy:
  – <validate-subscription> checks the key.
  – <authentication-managed-identity> obtains a bearer token for the APIM system-assigned identity.
  – <set-header Authorization> injects Bearer <token> so the backend call to the private Azure OpenAI endpoint is AAD-authenticated.

7. Logging & monitoring
- The existing APIM Diagnostic Settings send request/response logs and metrics to Log Analytics, where calls show up under the AzureDiagnostics table.

8. Key rotation / revocation
- User or admin can regenerate either key in the portal.
- Admin can set subscription state to Suspended or Cancelled to block access.

The whole process is self-service for developers (apart from the one-click approval, unless you pre-seed). 