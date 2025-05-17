#!/usr/bin/env bun

const { execSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

// The number of hours to count as "old"
const HOURS = 4;

// Get XDG_RUNTIME_DIR or fallback to /run/user/$(id -u)
const runtimeDir =
	process.env.XDG_RUNTIME_DIR || `/run/user/${process.getuid()}`;

// Path to the secrets directory
const secrets = path.join(runtimeDir, ".bubba");

// Check if the directory exists
if (fs.existsSync(secrets) && fs.lstatSync(secrets).isDirectory()) {
	let created;
	try {
		const stats = fs.statSync(secrets);
		created = Math.floor(stats.ctimeMs);
	} catch (e) {
		console.error(
			"Could not determine creation time of secrets directory:",
			e.message,
		);
		process.exit(1);
	}
	const now = Math.floor(Date.now());
	const fresh = now - HOURS * 3600 * 1000;

	console.log(
		`Secrets dir created: ${created} and ${HOURS} hours ago is: ${fresh}`,
	);

	// If created time is before "fresh", remove the directory
	if (created < fresh) {
		fs.rmSync(secrets, { recursive: true, force: true });
		console.log(`Deleted ${secrets}`);
	}
}
