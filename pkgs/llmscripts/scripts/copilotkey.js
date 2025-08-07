#!/usr/bin/env bun

import fs from "fs";
import path from "path";
import os from "os";
import { spawnSync } from "child_process";

function getKeysFilePath() {
	const uid = process.getuid();
	const xdgRuntimeDir = process.env.XDG_RUNTIME_DIR || `/run/user/${uid}`;
	return path.join(xdgRuntimeDir, "llmconf", "keys");
}

// Check if COPILOT_API_KEY is set and not expired
function checkExistingKey() {
	try {
		const keysFilePath = getKeysFilePath();
		if (!fs.existsSync(keysFilePath)) return false;

		const content = fs.readFileSync(keysFilePath, "utf8");
		const keyMatch = content.match(/COPILOT_API_KEY=([^\n]*)/);
		if (!keyMatch) return false;

		const currentKey = keyMatch[1];
		const expMatch = currentKey.match(/exp=(\d+)/);
		if (!expMatch) return false;

		const expTimestamp = Number.parseInt(expMatch[1], 10);
		const currentTime = Math.floor(Date.now() / 1000);
		const refreshThreshold = 15 * 60; // 15 minutes in seconds

		return expTimestamp > (currentTime + refreshThreshold);
	} catch (error) {
		console.error("# Error checking existing key:", error.message);
		return false;
	}
}

// Get GitHub auth token from config files
function getGitHubToken() {
	const configPaths = [
		path.join(os.homedir(), ".config", "github-copilot", "hosts.json"),
		path.join(os.homedir(), ".config", "github-copilot", "apps.json"),
	];

	for (const configPath of configPaths) {
		try {
			if (fs.existsSync(configPath)) {
				const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
				for (const host in config) {
					if (config[host]?.oauth_token) {
						return config[host].oauth_token;
					}
				}
			}
		} catch (error) {
			console.error(`# Error reading ${configPath}:`, error.message);
		}
	}

	throw new Error("GitHub token not found in config files");
}

// Fetch new Copilot API key
async function fetchNewKey(token) {
	try {
		const response = await fetch(
			"https://api.github.com/copilot_internal/v2/token",
			{
				headers: {
					Authorization: `Bearer ${token}`,
					"User-Agent": "GitHub-Copilot-Helper",
				},
			},
		);

		if (!response.ok) {
			throw new Error(`HTTP error! Status: ${response.status}`);
		}

		const data = await response.json();
		return data.token;
	} catch (error) {
		console.error("# Error fetching Copilot API key:", error.message);
		process.exit(1);
	}
}

async function updateKeysFile(newKey) {
	try {
		const keysFilePath = getKeysFilePath();

		// Create directory if it doesn't exist
		const dirPath = path.dirname(keysFilePath);
		if (!fs.existsSync(dirPath)) {
			fs.mkdirSync(dirPath, { recursive: true });
		}

		// Read existing file or create empty content
		let content = "";
		if (fs.existsSync(keysFilePath)) {
			content = fs.readFileSync(keysFilePath, "utf8");
		}

		// Replace existing COPILOT_API_KEY or add new one
		if (content.includes("COPILOT_API_KEY=")) {
			content = content.replace(
				/COPILOT_API_KEY=.*(\n|$)/,
				`COPILOT_API_KEY='${newKey}'\n`,
			);
		} else {
			content += `COPILOT_API_KEY='${newKey}'\n`;
		}

		// Write updated content back to file
		fs.writeFileSync(keysFilePath, content, "utf8");
		fs.chmodSync(keysFilePath, 0o600);
		//console.log(`Updated COPILOT_API_KEY in ${keysFilePath}`);

		// Restart the litellm systemd user unit
		// try {
		// 	const result = spawnSync("systemctl", ["--user", "restart", "litellm"]);
		// 	if (result.error || result.status !== 0) {
		// 		throw new Error(result.stderr?.toString() || "Unknown error");
		// 	}
		// 	console.log("Restarted litellm systemd user unit");
		// } catch (error) {
		// 	console.error(
		// 		`Failed to restart litellm systemd user unit: ${error.message}`,
		// 	);
		// }
	} catch (error) {
		console.error("# Error updating keys file:", error.message);
		throw error;
	}
}

// Check for internet connectivity to GitHub
async function checkGitHubConnectivity() {
	try {
		const response = await fetch("https://github.com", {
			method: "HEAD",
			signal: AbortSignal.timeout(3000), // 3 second timeout
		});
		return response.ok;
	} catch (error) {
		return false;
	}
}

async function main() {
	if (checkExistingKey()) {
		// Key is valid, nothing to do
		process.exit(0);
	}

	// First check for GitHub connectivity, retry every 5 seconds if not available
	let connected = await checkGitHubConnectivity();
	while (!connected) {
		// console.log("<5>copilotkey: Waiting for connectivity to GitHub...");
		console.log("# copilotkey: Waiting for connectivity to GitHub...");
		await new Promise((resolve) => setTimeout(resolve, 5000));
		connected = await checkGitHubConnectivity();
	}

	try {
		const githubToken = getGitHubToken();
		const newKey = await fetchNewKey(githubToken);

		// Update the keys file with the new key
		await updateKeysFile(newKey);

		// Print the key so it can be captured by the parent script if needed
		console.log(`export COPILOT_API_KEY='${newKey}'`);

		process.exit(0);
	} catch (error) {
		console.error("# Error:", error.message);
		process.exit(1);
	}
}

main();
