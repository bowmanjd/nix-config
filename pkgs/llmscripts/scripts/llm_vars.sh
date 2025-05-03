#!/bin/sh

llmconfig="$XDG_RUNTIME_DIR/llmconf"
mkdir -p "$llmconfig"
keyfile="$llmconfig/keys"
touch "$keyfile"

old_checksum=$(sha256sum "$keyfile" | rg -o '^\S+')

TAVILY_API_KEY=$(agegent ~/.ssh/secrets/tavily.enc.txt)
ANTHROPIC_API_KEY=$(agegent ~/.ssh/secrets/anthropic.enc.txt)
OPENROUTER_API_KEY=$(agegent ~/.ssh/secrets/openrouter.enc.txt)
GROQ_API_KEY=$(agegent ~/.ssh/secrets/groq.enc.txt)
GOOGLE_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GEMINI_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
OLLAMA_API_BASE=http://127.0.0.1:11434

cat > "$keyfile" <<EOF
# Auto-generated; do not edit
OLLAMA_API_BASE="$OLLAMA_API_BASE"
TAVILY_API_KEY=$TAVILY_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
GROQ_API_KEY=$GROQ_API_KEY
GOOGLE_API_KEY=$GOOGLE_API_KEY
GEMINI_API_KEY=$GEMINI_API_KEY
COPILOT_API_KEY='$COPILOT_API_KEY'
EOF

copilotkey.js
