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

  testDartWorkspace('publishDiagnostics reports lints', (ws) async {
    final ls = await ws.startLanguageServer();
    try {
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

      await ws.writeFileFromText('analysis_options.yaml', '''
linter:
  rules:
    - prefer_single_quotes
''');

      final fileUri = ws.workspaceFolder.resolve('main.dart');
      final code = 'void main() { print("hello"); }';

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
          (d) =>
              d.isA<Map>()['code'].isA<String>().equals('prefer_single_quotes'),
        ),
      );
    } finally {
      await ls.stop();
    }
  });

  testDartWorkspace('codeAction returns assists', (ws) async {
    final ls = await ws.startLanguageServer();
    try {
      final lsp = Peer.withoutJson(ls.languageServerChannel);

      unawaited(lsp.listen());

      await lsp.sendRequest('initialize', {
        'processId': null,
        'rootUri': ws.workspaceFolder.toString(),
        'capabilities': {
          'textDocument': {
            'codeAction': {
              'codeActionLiteralSupport': {
                'codeActionKind': {
                  'valueSet': ['refactor'],
                },
              },
            },
          },
        },
      });

      lsp.sendNotification('initialized', {});

      final fileUri = ws.workspaceFolder.resolve('main.dart');
      final code = 'void main() { print("hello"); }';

      lsp.sendNotification('textDocument/didOpen', {
        'textDocument': {
          'uri': fileUri.toString(),
          'languageId': 'dart',
          'version': 1,
          'text': code,
        },
      });

      final codeActions = await lsp.sendRequest('textDocument/codeAction', {
        'textDocument': {'uri': fileUri.toString()},
        'range': {
          'start': {'line': 0, 'character': 5},
          'end': {'line': 0, 'character': 5},
        },
        'context': {'diagnostics': <Map<String, Object?>>[]},
      });

      check(codeActions).isA<List>().any(
        (action) => action.isA<Map>()['title'].isA<String>().contains(
          'Convert to expression body',
        ),
      );
    } finally {
      await ls.stop();
    }
  });

  testDartWorkspace('codeAction returns fixes', (ws) async {
    final ls = await ws.startLanguageServer();
    try {
      final lsp = Peer.withoutJson(ls.languageServerChannel);

      final diagnosticsCompleter = Completer<Map<String, Object?>>();
      lsp.registerMethod('textDocument/publishDiagnostics', (
        Parameters params,
      ) {
        if (!diagnosticsCompleter.isCompleted) {
          diagnosticsCompleter.complete(params.value as Map<String, Object?>);
        }
      });

      unawaited(lsp.listen());

      await lsp.sendRequest('initialize', {
        'processId': null,
        'rootUri': ws.workspaceFolder.toString(),
        'capabilities': {
          'textDocument': {
            'publishDiagnostics': <String, Object?>{},
            'codeAction': {
              'codeActionLiteralSupport': {
                'codeActionKind': {
                  'valueSet': ['quickfix'],
                },
              },
            },
          },
        },
      });
      lsp.sendNotification('initialized', {});

      await ws.writeFileFromText('analysis_options.yaml', '''
linter:
  rules:
    - prefer_single_quotes
''');

      final fileUri = ws.workspaceFolder.resolve('main.dart');
      final code = 'void main() { print("hello"); }';

      lsp.sendNotification('textDocument/didOpen', {
        'textDocument': {
          'uri': fileUri.toString(),
          'languageId': 'dart',
          'version': 1,
          'text': code,
        },
      });

      final diagnosticsResponse = await diagnosticsCompleter.future;
      final diagnostics = (diagnosticsResponse['diagnostics'] as List)
          .cast<Map>();
      final diagnostic = diagnostics.firstWhere(
        (d) => d['code'] == 'prefer_single_quotes',
      );

      final codeActions = await lsp.sendRequest('textDocument/codeAction', {
        'textDocument': {'uri': fileUri.toString()},
        'range': diagnostic['range'],
        'context': {
          'diagnostics': [diagnostic],
        },
      });

      check(codeActions).isA<List>().any(
        (action) => action.isA<Map>()['title'].isA<String>().contains(
          'Convert to single quoted string',
        ),
      );
    } finally {
      await ls.stop();
    }
  });
}
