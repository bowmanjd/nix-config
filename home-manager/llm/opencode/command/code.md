---
description: Emit only code
agent: build
model: openrouter/qwen/qwen3-coder-30b-a3b-instruct
---

Provide only code without comments or explanations.
### INPUT:
async sleep in js
### OUTPUT:
```javascript
async function timeout(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

$ARGUMENTS
