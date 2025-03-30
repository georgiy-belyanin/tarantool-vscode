import * as assert from 'assert';
import * as vscode from 'vscode';

const chai = require('chai');
const spies = require('chai-spies');

const expect = chai.expect;

chai.use(spies);

suite('Commands', () => {
	const mockTerminal = {
		sendText: chai.spy(() => {}),
		show: chai.spy(() => {}),
	};

	const mockTerminalCreate = chai.spy.on(vscode.window, 'createTerminal', () => mockTerminal);

	function testCmd(command: string, expected: string) {
		return async () => {
			await vscode.commands.executeCommand('tarantool.' + command);
			await new Promise(resolve => setTimeout(resolve, 100));

			expect(mockTerminalCreate).to.have.been.called.with('Tarantool');
			expect(mockTerminal.show).to.have.been.called.with(true);
			expect(mockTerminal.sendText).to.have.been.called.with('tt ' + expected);
		};
	}

	test('Init', testCmd('init', 'init'));
	test('Start', testCmd('start', 'start -i &'));
	test('Status', testCmd('stat', 'status -p'));
	test('Stop', testCmd('stop', 'stop -y'));
	test('Restart', testCmd('restart', 'restart -y'));
	// TODO: Check `install-ce` command.

	test('Init in existing', function() {
		vscode.workspace.openTextDocument();
	});
});
