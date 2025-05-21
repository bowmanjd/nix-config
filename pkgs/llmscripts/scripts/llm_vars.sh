#!/bin/sh

llmconfig="$XDG_RUNTIME_DIR/llmconf"
mkdir -p "$llmconfig"
keyfile="$llmconfig/keys"
touch "$keyfile"

TAVILY_API_KEY=$(agegent ~/.ssh/secrets/tavily.enc.txt)
OPENAI_API_KEY=$(agegent ~/.ssh/secrets/openai.enc.txt)
ANTHROPIC_API_KEY=$(agegent ~/.ssh/secrets/anthropic.enc.txt)
OPENROUTER_API_KEY=$(agegent ~/.ssh/secrets/openrouter.enc.txt)
GROQ_API_KEY=$(agegent ~/.ssh/secrets/groq.enc.txt)
GOOGLE_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GEMINI_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GITHUB_API_KEY=$(agegent ~/.ssh/secrets/copilot.enc.txt)
HF_TOKEN=$(agegent ~/.ssh/secrets/huggingface.enc.txt)

cat > "$keyfile" <<EOF
# Auto-generated; do not edit
OLLAMA_API_BASE=http://127.0.0.1:11434
LITELLM_PROXY_API_BASE=http://127.0.0.1:1173
LITELLM_PROXY_API_KEY="fake_key_123"
TAVILY_API_KEY=$TAVILY_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
GROQ_API_KEY=$GROQ_API_KEY
GOOGLE_API_KEY=$GOOGLE_API_KEY
GEMINI_API_KEY=$GEMINI_API_KEY
GITHUB_API_KEY=$GITHUB_API_KEY
HF_TOKEN=$HFTOKEN
COPILOT_API_KEY='$COPILOT_API_KEY'
EOF

copilotkey.js
