#!/usr/bin/env bun

import fs from 'fs';
import path from 'path';
import os from 'os';

// Check if COPILOT_API_KEY is set and not expired
function checkExistingKey() {
  const currentKey = process.env.COPILOT_API_KEY;
  if (!currentKey) return false;
  
  const expMatch = currentKey.match(/exp=(\d+)/);
  if (!expMatch) return false;
  
  const expTimestamp = parseInt(expMatch[1], 10);
  const currentTime = Math.floor(Date.now() / 1000);
  
  return expTimestamp > currentTime;
}

// Get GitHub auth token from config files
function getGitHubToken() {
  const configPaths = [
    path.join(os.homedir(), '.config', 'github-copilot', 'hosts.json'),
    path.join(os.homedir(), '.config', 'github-copilot', 'apps.json')
  ];
  
  for (const configPath of configPaths) {
    try {
      if (fs.existsSync(configPath)) {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        for (const host in config) {
          if (config[host]?.oauth_token) {
            return config[host].oauth_token;
          }
        }
      }
    } catch (error) {
      console.error(`Error reading ${configPath}:`, error.message);
    }
  }
  
  throw new Error('GitHub token not found in config files');
}

// Fetch new Copilot API key
async function fetchNewKey(token) {
  try {
    const response = await fetch('https://api.github.com/copilot_internal/v2/token', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'User-Agent': 'GitHub-Copilot-Helper'
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    return data.token;
  } catch (error) {
    console.error('Error fetching Copilot API key:', error.message);
    process.exit(1);
  }
}

async function main() {
  if (checkExistingKey()) {
    // Key is valid, nothing to do
    process.exit(0);
  }
  
  try {
    const githubToken = getGitHubToken();
    const newKey = await fetchNewKey(githubToken);
    
    // Set the new key in the environment
    process.env.COPILOT_API_KEY = newKey;
    
    // Print the key so it can be captured by the parent script if needed
    console.log(`export COPILOT_API_KEY='${newKey}'`);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();

