import * as vscode from 'vscode';
import commandExists = require('command-exists');
import { Octokit } from '@octokit/core';

const octokit = new Octokit();

const TerminalLabel = 'Tarantool';

function getTerminal(): vscode.Terminal {
	const terminal = vscode.window.terminals.find(t => t.name === TerminalLabel) ||
		vscode.window.createTerminal(TerminalLabel);
	terminal.show(true);
	return terminal;
}

function isTerminalRunning(): boolean {
	const terminals = vscode.window.terminals;
	return terminals.find(t => t.name === TerminalLabel) !== undefined;
}

function cmd(body: string) {
	return async () => {
		commandExists('tt').then(() => {
			const t = getTerminal();
			t.sendText('tt ' + body);
		}).catch(function () {
			vscode.window.showErrorMessage('TT is not installed');
		});
	};
}

async function getCeVersions(): Promise<string[]> {
	const res = await octokit.request('GET https://api.github.com/repos/tarantool/tarantool/tags');
	return res.data.map((tag: { name: string }) => tag.name)
		.filter((version: string) => version.match(/^\d+\.\d+\.\d+$/));
}

export const init = cmd('init');
export const start = cmd('start -i &');
export const stop = cmd('stop -y');
export const stat = cmd('status -p');
export const restart = cmd('restart -y');
export const installCe = function () {
	vscode.window.showInformationMessage('Installing Tarantool Community Edition');
	getCeVersions().then(async versions => {
		const version = await vscode.window.showQuickPick(versions);
		if (!version) {return;}

		vscode.window.showInformationMessage('Installing Tarantool Community Edition ' + version);
		getTerminal().sendText('tt install tarantool ' + version);
	}).catch(err => {
		vscode.window.showErrorMessage('Unable to fetch Tarantool version list: ' + err.message);
	});
};
