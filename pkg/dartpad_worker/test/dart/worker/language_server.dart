// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('initialize returns capabilities', (ws) async {
    final ls = await ws.startLanguageServer();

    final lsp = Peer.withoutJson(ls.languageServerChannel);
    unawaited(lsp.listen());

    final r = await lsp.sendRequest('initialize', {
      'processId': null,
      'rootUri': ws.workspaceFolder.toString(),
      'capabilities': <String, Object?>{},
    });

    check(r).isA<Map>()['capabilities'].isA<Map>()
      ..containsKey('textDocumentSync')
      ..containsKey('hoverProvider')
      ..containsKey('completionProvider');

    await ls.stop();
  });

  testDartWorkspace('publishDiagnostics reports syntax errors', (ws) async {
    final ls = await ws.startLanguageServer();
    final lsp = Peer.withoutJson(ls.languageServerChannel);
    unawaited(lsp.listen());

    await lsp.sendRequest('initialize', {
      'processId': null,
      'rootUri': ws.workspaceFolder.toString(),
      'capabilities': {
        'textDocument': {'publishDiagnostics': <String, Object?>{}},
      },
    });
    lsp.sendNotification('initialized', {});

    final diagnosticsQueue = check(
      lsp,
    ).withNotificationQueue('textDocument/publishDiagnostics');

    final fileUri = ws.workspaceFolder.resolve('main.dart');
    final code = 'void main() { print("hello") }'; // Missing semicolon

    lsp.sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': fileUri.toString(),
        'languageId': 'dart',
        'version': 1,
        'text': code,
      },
    });

    await diagnosticsQueue.emitsThrough(
      (e) => e.isA<Map>()['diagnostics'].isA<List>().any(
        (d) => d.isA<Map>()['message'].isA<String>().contains(
          'Expected to find \';\'',
        ),
      ),
    );

    await ls.stop();
  });

  testDartWorkspace('hover returns information', (ws) async {
    final ls = await ws.startLanguageServer();
    final lsp = Peer.withoutJson(ls.languageServerChannel);
    unawaited(lsp.listen());

    await lsp.sendRequest('initialize', {
      'processId': null,
      'rootUri': ws.workspaceFolder.toString(),
      'capabilities': {
        'textDocument': {
          'hover': {
            'contentFormat': ['plaintext'],
          },
        },
      },
    });
    lsp.sendNotification('initialized', {});

    final fileUri = ws.workspaceFolder.resolve('main.dart');
    final code = 'void main() { print("hello"); }';
    await ws.writeFileFromText('main.dart', code);

    lsp.sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': fileUri.toString(),
        'languageId': 'dart',
        'version': 1,
        'text': code,
      },
    });

    // Position of 'print' is line 0, character 14
    final hover = await lsp.sendRequest('textDocument/hover', {
      'textDocument': {'uri': fileUri.toString()},
      'position': {'line': 0, 'character': 15},
    });
    check(hover).isA<Map>()['contents'].isA<Map>()['value'].isA<String>()
      ..contains('print')
      ..contains('void');

    await ls.stop();
  });

  testDartWorkspace('diagnostics update after didChange', (ws) async {
    final ls = await ws.startLanguageServer();
    final lsp = Peer.withoutJson(ls.languageServerChannel);
    unawaited(lsp.listen());

    await lsp.sendRequest('initialize', {
      'processId': null,
      'rootUri': ws.workspaceFolder.toString(),
      'capabilities': {
        'textDocument': {'publishDiagnostics': <String, Object?>{}},
      },
    });
    lsp.sendNotification('initialized', {});

    final diagnosticsQueue = check(
      lsp,
    ).withNotificationQueue('textDocument/publishDiagnostics');

    final fileUri = ws.workspaceFolder.resolve('main.dart').toString();

    // Open with error
    lsp.sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': fileUri,
        'languageId': 'dart',
        'version': 1,
        'text': 'void main() { print("hi") }',
      },
    });

    await diagnosticsQueue.emitsThrough(
      (e) => e.isA<Map>()['diagnostics'].isA<List>().isNotEmpty(),
    );

    // Fix it
    lsp.sendNotification('textDocument/didChange', {
      'textDocument': {'uri': fileUri, 'version': 2},
      'contentChanges': [
        {'text': 'void main() { print("hi"); }'},
      ],
    });

    await diagnosticsQueue.emitsThrough(
      (e) => e.isA<Map>()['diagnostics'].isA<List>().isEmpty(),
    );

    await ls.stop();
  });
}
