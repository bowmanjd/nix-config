#!/bin/sh



export TAVILY_API_KEY=$(agegent ~/.ssh/secrets/tavily.enc.txt)
export ANTHROPIC_API_KEY=$(agegent ~/.ssh/secrets/anthropic.enc.txt)
export OPENROUTER_API_KEY=$(agegent ~/.ssh/secrets/openrouter.enc.txt)
export GROQ_API_KEY=$(agegent ~/.ssh/secrets/groq.enc.txt)
export GOOGLE_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
export GEMINI_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
export OLLAMA_API_BASE=http://127.0.0.1:11434
eval $(copilotkey.js)

llmconfig="$HOME/.config/llmconf"
mkdir -p "$llmconfig"
keyfile="$llmconfig/keys"
touch "$keyfile"
chmod 0600 "$keyfile"
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
