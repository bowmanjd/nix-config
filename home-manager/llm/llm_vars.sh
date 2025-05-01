#!/bin/sh

OPENAI_API_KEY=$(agegent ~/.ssh/secrets/openai.enc.txt)
TAVILY_API_KEY=$(agegent ~/.ssh/secrets/tavily.enc.txt)
ANTHROPIC_API_KEY=$(agegent ~/.ssh/secrets/anthropic.enc.txt)
OPENROUTER_API_KEY=$(agegent ~/.ssh/secrets/openrouter.enc.txt)
GROQ_API_KEY=$(agegent ~/.ssh/secrets/groq.enc.txt)
GOOGLE_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GEMINI_API_KEY=$(agegent ~/.ssh/secrets/gemini.enc.txt)
GITHUB_API_KEY=$(agegent ~/.ssh/secrets/copilot.enc.txt)
OLLAMA_API_BASE=http://127.0.0.1:11434
eval $(copilotkey.js)
