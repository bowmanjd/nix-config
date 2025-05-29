#!/bin/sh

llmconfig="$XDG_RUNTIME_DIR/llmconf"
mkdir -p "$llmconfig"
keyfile="$llmconfig/keys"
touch "$keyfile"

TAVILY_API_KEY=$(agegent ~/.ssh/secrets/tavily.enc.txt)
GOOGLE_SEARCH_API_KEY=$(agegent ~/.ssh/secrets/google_search.enc.txt)
OPENAI_API_KEY=$(agegent ~/.ssh/secrets/openai.enc.txt)
ANTHROPIC_API_KEY=$(agegent ~/.ssh/secrets/anthropic.enc.txt)
OPENROUTER_API_KEY=$(agegent ~/.ssh/secrets/openrouter.enc.txt)
GROQ_API_KEY=$(agegent ~/.ssh/secrets/groq.enc.txt)
GOOGLE_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GEMINI_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GITHUB_API_KEY=$(agegent ~/.ssh/secrets/copilot.enc.txt)
HF_TOKEN=$(agegent ~/.ssh/secrets/huggingface.enc.txt)
CLOUDFLARE_API_KEY=$(agegent ~/.ssh/secrets/cloudflare_token.enc.txt)
CLOUDFLARE_ACCOUNT_ID=$(agegent ~/.ssh/secrets/cloudflare_id.enc.txt)
CEREBRAS_API_KEY=$(agegent ~/.ssh/secrets/cerebras.enc.txt)
SAMBANOVA_API_KEY=$(agegent ~/.ssh/secrets/sambanova.enc.txt)
CODESTRAL_API_KEY=$(agegent ~/.ssh/secrets/codestral.enc.txt)
TOGETHERAI_API_KEY=$(agegent ~/.ssh/secrets/together.enc.txt)
MISTRAL_API_KEY=$(agegent ~/.ssh/secrets/mistral.enc.txt)
NVIDIA_NIM_API_KEY=$(agegent ~/.ssh/secrets/nvidia.enc.txt)

cat > "$keyfile" <<EOF
# Auto-generated; do not edit

# Open WebUI:
CUSTOM_NAME="Chat Like an Owner"
WEBUI_NAME="Chat Like an Owner"
ENABLE_WEB_SEARCH=True
WEB_SEARCH_ENGINE=google_pse
GOOGLE_PSE_ENGINE_ID=626da60bfa6e445c8
GOOGLE_PSE_API_KEY=$GOOGLE_SEARCH_API_KEY

OLLAMA_API_BASE=http://127.0.0.1:11434
LITELLM_PROXY_API_BASE=http://127.0.0.1:1173
LITELLM_PROXY_API_KEY="fake_key_123"
TAVILY_API_KEY=$TAVILY_API_KEY
GOOGLE_SEARCH_API_KEY=$GOOGLE_SEARCH_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
GROQ_API_KEY=$GROQ_API_KEY
GOOGLE_API_KEY=$GOOGLE_API_KEY
GEMINI_API_KEY=$GEMINI_API_KEY
GITHUB_API_KEY=$GITHUB_API_KEY
HF_TOKEN=$HF_TOKEN
CLOUDFLARE_API_KEY=$CLOUDFLARE_API_KEY
CLOUDFLARE_ACCOUNT_ID=$CLOUDFLARE_ACCOUNT_ID
CEREBRAS_API_KEY=$CEREBRAS_API_KEY
SAMBANOVA_API_KEY=$SAMBANOVA_API_KEY
CODESTRAL_API_KEY=$CODESTRAL_API_KEY
MISTRAL_API_KEY=$MISTRAL_API_KEY
MISTRAL_OCR_API_KEY=$MISTRAL_API_KEY
TOGETHERAI_API_KEY=$TOGETHERAI_API_KEY
NVIDIA_NIM_API_KEY=$NVIDIA_NIM_API_KEY
COPILOT_API_KEY='$COPILOT_API_KEY'
EOF

copilotkey.js
