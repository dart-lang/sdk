// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Location {
  final Uri uri;
  final int line;
  final int column;

  Location(this.uri, this.line, this.column);

  @override
  String toString() => 'Location[$uri:$line:$column]';
}

class LspMessages {
  static Map<String, dynamic> initNotification = {
    'jsonrpc': '2.0',
    'method': 'initialized',
    'params': {},
  };

  static Map<String, dynamic> codeAction(
    int id,
    Uri uri, {
    required int line,
    required int character,
  }) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/codeAction',
      'params': {
        'textDocument': {'uri': '$uri'},
        'range': {
          'start': {'line': line, 'character': character},
          'end': {'line': line, 'character': character},
        },
        'context': {'diagnostics': [], 'triggerKind': 2},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> codeActionRange(
    int id,
    Uri uri, {
    required int lineFrom,
    required int characterFrom,
    required int lineTo,
    required int characterTo,
  }) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/codeAction',
      'params': {
        'textDocument': {'uri': '$uri'},
        'range': {
          'start': {'line': lineFrom, 'character': characterFrom},
          'end': {'line': lineTo, 'character': characterTo},
        },
        'context': {'diagnostics': [], 'triggerKind': 2},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> completion(
    Uri uri,
    int id, {
    required int line,
    required int character,
  }) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/completion',
      'params': {
        'textDocument': {'uri': '$uri'},
        'position': {'line': line, 'character': character},
        'context': {'triggerKind': 1},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> didChange(
    Uri uri, {
    required int version,
    required int insertAtLine,
    int insertAtCharacter = 0,
    required String insert,
  }) {
    return {
      'jsonrpc': '2.0',
      'method': 'textDocument/didChange',
      'params': {
        'textDocument': {'uri': '$uri', 'version': version},
        'contentChanges': [
          {
            'range': {
              'start': {'line': insertAtLine, 'character': insertAtCharacter},
              'end': {'line': insertAtLine, 'character': insertAtCharacter},
            },
            'rangeLength': 0,
            'text': insert,
          },
        ],
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> documentColor(Uri uri, int id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/documentColor',
      'params': {
        'textDocument': {'uri': '$uri'},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> documentSymbol(Uri uri, int id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/documentSymbol',
      'params': {
        'textDocument': {'uri': '$uri'},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> gotoDef(int id, Location location) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/definition',
      'params': {
        'textDocument': {'uri': '${location.uri}'},
        'position': {'line': location.line, 'character': location.column},
      },
    };
  }

  static Map<String, dynamic> implementation(int id, Location location) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/implementation',
      'params': {
        'textDocument': {'uri': '${location.uri}'},
        'position': {'line': location.line, 'character': location.column},
      },
    };
  }

  static Map<String, dynamic> initMessage(
    int processId,
    Uri rootUri,
    List<Uri> additionalWorkspaceUris,
  ) {
    String rootPath = rootUri.toFilePath();
    String name = rootUri.pathSegments.last;
    if (name.isEmpty) {
      name = rootUri.pathSegments[rootUri.pathSegments.length - 2];
    }
    return {
      'jsonrpc': '2.0',
      'id': 0,
      'method': 'initialize',
      'params': {
        'processId': processId,
        'clientInfo': {'name': 'lspTestScript', 'version': '0.0.2'},
        'locale': 'en',
        'rootPath': rootPath,
        'rootUri': '$rootUri',
        'capabilities': {
          'textDocument': {
            'codeAction': {
              // needed for the plugin to trigger on codeAction.
              'codeActionLiteralSupport': {
                'codeActionKind': {
                  'valueSet': [
                    '',
                    'quickfix',
                    'refactor',
                    'refactor.extract',
                    'refactor.inline',
                    'refactor.rewrite',
                    'source',
                    'source.organizeImports',
                  ],
                },
              },
            },
          },
        },
        'workspaceFolders': [
          {'uri': '$rootUri', 'name': name},
          ...additionalWorkspaceUris.map((uri) {
            String name = uri.pathSegments.last;
            if (name.isEmpty) {
              name = uri.pathSegments[uri.pathSegments.length - 2];
            }
            return {'uri': '$uri', 'name': name};
          }),
        ],
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> open(Uri uri, int version, String content) {
    return {
      'jsonrpc': '2.0',
      'method': 'textDocument/didOpen',
      'params': {
        'textDocument': {
          'uri': '$uri',
          'languageId': 'dart',
          'version': version,
          'text': content,
        },
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> references(int id, Location location) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/references',
      'params': {
        'textDocument': {'uri': '${location.uri}'},
        'position': {'line': location.line, 'character': location.column},
        'context': {'includeDeclaration': true},
      },
    };
  }

  static Map<String, dynamic> semanticTokensFull(Uri uri, int id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': 'textDocument/semanticTokens/full',
      'params': {
        'textDocument': {'uri': '$uri'},
      },
      'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
