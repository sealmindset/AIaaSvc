
# Pre-register the needed providers

```
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.BotService
```

# OpenAI a.k.a., CognitiveServices

```
az provider register --namespace Microsoft.CognitiveServices  --wait
```

# Optional: verify registration state

```
az provider show --namespace Microsoft.CognitiveServices --query "registrationState"
```