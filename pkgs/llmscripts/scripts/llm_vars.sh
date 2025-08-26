#!/bin/sh

llmconfig="$XDG_RUNTIME_DIR/llmconf"
mkdir -p "$llmconfig"
keyfile="$llmconfig/keys"
webuifile="$llmconfig/webui"
touch "$keyfile"
touch "$webuifile"

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
LITELLM_KEY=$(agegent ~/.ssh/secrets/litellm-key.enc.txt)
LITELLM_SALT=$(agegent ~/.ssh/secrets/litellm-salt.enc.txt)

cat > "$webuifile" <<EOF
# Auto-generated; do not edit

# Open WebUI:
STATIC_DIR="$HOME/.local/share/webui/static"
DATA_DIR="$HOME/.local/share/webui/data"
HF_HOME="$HOME/.local/share/webui"
SENTENCE_TRANSFORMERS_HOME="$HOME/.local/share/webui"
WEBUI_URL=http://webui.home.arpa
ENABLE_PERSISTENT_CONFIG=False
CUSTOM_NAME="Chat Like an Owner"
WEBUI_NAME="Chat Like an Owner"
OPENAI_API_BASE_URL=http://127.0.0.1:1173
OPENAI_API_KEY=$LITELLM_KEY
ENABLE_OLLAMA_API=False
ENABLE_WEB_SEARCH=True
ENABLE_EVALUATION_ARENA_MODELS=False
WEB_SEARCH_ENGINE=google_pse
GOOGLE_PSE_ENGINE_ID=626da60bfa6e445c8
GOOGLE_PSE_API_KEY=$GOOGLE_SEARCH_API_KEY
RAG_EMBEDDING_ENGINE=ollama
RAG_EMBEDDING_MODEL=granite-embedding:30m
RAG_TOP_K=5
RAG_TOP_K_RERANKER=5
# RAG_RERANKING_MODEL=
EOF

cat > "$keyfile" <<EOF
# Auto-generated; do not edit

OLLAMA_HOST=127.0.0.1
OLLAMA_API_BASE="http://$OLLAMA_HOST:11434"
LITELLM_PROXY_API_BASE=http://127.0.0.1:1173

# Goose:
GOOSE_DISABLE_KEYRING=true
GOOSE_CONTEXT_STRATEGY=prompt
GOOSE_MODE=smart_approve
LITELLM_HOST=$LITELLM_PROXY_API_BASE
LITELLM_BASE_PATH=/chat/completions
GOOSE_EDITOR_API_KEY="$LITELLM_KEY"
GOOSE_EDITOR_HOST="$LITELLM_PROXY_API_BASE"
GOOSE_EDITOR_MODEL="gpt-4.1"

# Fraude Code
CLAUDE_MODEL=gpt-5-mini
CLAUDE_SMALL=gpt-4.1
CLAUDE_MAX_OUTPUT=16384

# Claude Code
DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

LITELLM_PROXY_API_KEY=$LITELLM_KEY
LITELLM_API_KEY=$LITELLM_KEY
LITELLM_MASTER_KEY=$LITELLM_KEY
LITELLM_SALT_KEY=$LITELLM_SALT_KEY
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
EOF

# copilotkey.js
