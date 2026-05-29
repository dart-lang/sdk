// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';

import '../../worker_harness.dart';

void main() {
  testFlutterWorkspace('initialize returns capabilities', (ws) async {
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

  testFlutterWorkspace('hover flutter widget', (ws) async {
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
    final code = [
      'import \'package:flutter/material.dart\';',
      '',
      'void main() {',
      '  runApp(const Center(child: Text(\'Hello World\')));',
      '}',
    ].join('\n');
    await ws.writeFileFromText('main.dart', code);

    lsp.sendNotification('textDocument/didOpen', {
      'textDocument': {
        'uri': fileUri.toString(),
        'languageId': 'dart',
        'version': 1,
        'text': code,
      },
    });

    // Position of 'Center' is line 3, character 16
    final hover = await lsp.sendRequest('textDocument/hover', {
      'textDocument': {'uri': fileUri.toString()},
      'position': {'line': 3, 'character': 16},
    });

    check(hover).isA<Map>()['contents'].isA<Map>()['value'].isA<String>()
      ..contains('Center')
      ..contains('Widget');

    await ls.stop();
  });

  testFlutterWorkspace('diagnostics report errors in flutter code', (ws) async {
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
    final code = '''
      import 'package:flutter/material.dart';

      void main() {
        runApp(Center(child: TypoWidget('Hello World')));
      }
    ''';

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
        (d) => d.isA<Map>()['message'].isA<String>().contains('TypoWidget'),
      ),
    );

    await ls.stop();
  });
}
