// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/log_sanitizer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogSanitizerTest);
  });
}

@reflectiveTest
class LogSanitizerTest {
  late LogSanitizer sanitizer;

  void setUp() {
    sanitizer = LogSanitizer();
  }

  void test_commandLine_paths() {
    var entry = {
      key.kind: EntryKind.commandLine.name,
      key.argList: [
        '--protocol=lsp',
        '--client-id=VS-Code',
        '--instrumentation-log-file=/Users/user/analyzerInstrumentation.txt',
        '--session-log=/Users/user/session.json',
        'confidential.dart',
      ],
    };

    var result = sanitizer.sanitizeEntry(entry);
    expect(result, {
      key.kind: EntryKind.commandLine.name,
      key.argList: [
        '--protocol=lsp',
        '--client-id=VS-Code',
        '--instrumentation-log-file=/p0/p1/p2',
        '--session-log=/p0/p1/p3',
        '...',
      ],
    });
  }

  void test_exception_and_info_paths() {
    var exceptionEntry = {
      key.kind: EntryKind.exception.name,
      key.message: 'Error in file:///Users/user/project/lib/main.dart',
      key.stackTrace: 'at /Users/user/project/lib/main.dart:10:5',
    };

    var result = sanitizer.sanitizeEntry(exceptionEntry);
    expect(result, {
      key.kind: EntryKind.exception.name,
      key.message: 'Error in file:///p0/p1/p2/p3/p4.dart',
      key.stackTrace: 'at /p0/p1/p2/p3/p4.dart:10:5',
    });

    var infoEntry = {
      key.kind: EntryKind.info.name,
      key.message: 'Loaded context at /Users/user/project',
    };
    var infoResult = sanitizer.sanitizeEntry(infoEntry);
    expect(infoResult, {
      key.kind: EntryKind.info.name,
      key.message: 'Loaded context at /p0/p1/p2',
    });
  }

  void test_message_codeAction() {
    // Request is processed first to register the method for ID 10.
    sanitizer.sanitizeMessage({
      'id': 10,
      'method': 'textDocument/codeAction',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 10,
      'jsonrpc': '2.0',
      'result': [
        {
          'title': "Rename '_foo' to 'foo'",
          'edit': {
            'changes': {
              'file:///test/lib/main.dart': [
                {
                  'newText': 'foo',
                  'range': {
                    'start': {'line': 0, 'character': 0},
                    'end': {'line': 0, 'character': 4},
                  },
                },
              ],
            },
          },
        },
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'title': "Rename 'a1' to 'a2'",
        'edit': {
          'changes': {
            'file:///p0/p1/p2.dart': [
              {
                'newText': 'a2',
                'range': {
                  'start': {'line': 0, 'character': 0},
                  'end': {'line': 0, 'character': 4},
                },
              },
            ],
          },
        },
      },
    ]);
  }

  void test_message_codeLens() {
    // Request is processed first to register the method for ID 11.
    sanitizer.sanitizeMessage({
      'id': 11,
      'method': 'textDocument/codeLens',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 11,
      'jsonrpc': '2.0',
      'result': [
        {
          'command': {
            'title': 'Run | Debug',
            'command': 'dart.test',
            'arguments': ['file:///test/lib/main.dart'],
          },
        },
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'command': {
          'title': 'Run | Debug',
          'command': 'dart.test',
          'arguments': ['file:///p0/p1/p2.dart'],
        },
      },
    ]);
  }

  void test_message_command_resolve() {
    // Request is processed first to register the method for ID 20.
    sanitizer.sanitizeMessage({
      'id': 20,
      'method': 'command/resolve',
      'params': {
        'command': 'dart.edit.organizeImports',
        'arguments': [
          {'path': 'file:///test/lib/main.dart', 'autoTriggered': true},
        ],
      },
    });

    var message = {
      'id': 20,
      'jsonrpc': '2.0',
      'result': {
        'command': 'dart.edit.organizeImports',
        'arguments': [
          {'path': 'file:///test/lib/main.dart', 'autoTriggered': true},
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], {
      'command': 'dart.edit.organizeImports',
      'arguments': [
        {'path': 'file:///p0/p1/p2.dart', 'autoTriggered': true},
      ],
    });
  }

  void test_message_completion() {
    // Request is processed first to register the method for ID 21.
    sanitizer.sanitizeMessage({
      'id': 21,
      'method': 'textDocument/completion',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
        'position': {'line': 5, 'character': 10},
      },
    });

    var message = {
      'id': 21,
      'jsonrpc': '2.0',
      'result': {
        'isIncomplete': false,
        'items': [
          {
            'label': 'MyWidget',
            'kind': 7, // Class
            'detail': 'Auto import from package:test/widget.dart',
            'labelDetails': {'description': 'package:test/widget.dart'},
            'documentation': {
              'kind': 'markdown',
              'value': 'Some documentation',
            },
            'data': {
              'file': 'file:///test/lib/main.dart',
              'importUris': ['package:test/widget.dart'],
              'ref': 'package:test/widget.dart;MyWidget;helper',
            },
          },
          {
            'label': 'myFunction',
            'kind': 3, // Function
            'documentation': 'Plain text doc',
          },
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], {
      'isIncomplete': false,
      'items': [
        {
          'label': 'C1',
          'kind': 7,
          'detail': '<sanitized>',
          'labelDetails': {'description': 'package:p0/p3.dart'},
          'documentation': {'kind': 'markdown', 'value': '<18 chars>'},
          'data': {
            'file': 'file:///p0/p1/p2.dart',
            'importUris': ['package:p0/p3.dart'],
            'ref': 'package:p0/p3.dart;C1;a1',
          },
        },
        {'label': 'm1', 'kind': 3, 'documentation': '<14 chars>'},
      ],
    });
  }

  void test_message_completionItem_resolve() {
    // Request is processed first to register the method for ID 22.
    sanitizer.sanitizeMessage({
      'id': 22,
      'method': 'completionItem/resolve',
      'params': {
        'label': 'MyWidget',
        'kind': 7,
        'data': {
          'file': 'file:///test/lib/main.dart',
          'importUris': ['package:test/widget.dart'],
          'ref': 'package:test/widget.dart;MyWidget',
        },
      },
    });

    var message = {
      'id': 22,
      'jsonrpc': '2.0',
      'result': {
        'label': 'MyWidget',
        'kind': 7,
        'detail': 'Auto import from package:test/widget.dart',
        'documentation': {'kind': 'markdown', 'value': 'Some documentation'},
        'data': {
          'file': 'file:///test/lib/main.dart',
          'importUris': ['package:test/widget.dart'],
          'ref': 'package:test/widget.dart;MyWidget',
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], {
      'label': 'C1',
      'kind': 7,
      'detail': '<sanitized>',
      'documentation': {'kind': 'markdown', 'value': '<18 chars>'},
      'data': {
        'file': 'file:///p0/p1/p2.dart',
        'importUris': ['package:p0/p3.dart'],
        'ref': 'package:p0/p3.dart;C1',
      },
    });
  }

  void test_message_didChange_incremental() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'textDocument/didChange',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart', 'version': 2},
        'contentChanges': [
          {
            'range': {
              'start': {'line': 1, 'character': 0},
              'end': {'line': 1, 'character': 5},
            },
            'text': 'myVariable',
          },
          {
            // Without range
            'text': 'anotherIdent',
          },
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'textDocument': {'uri': 'file:///p0/p1/p2.dart', 'version': 2},
      'contentChanges': [
        {
          'range': {
            'start': {'line': 1, 'character': 0},
            'end': {'line': 1, 'character': 5},
          },
          'text': 'a1',
        },
        {'text': 'a2'},
      ],
    });
  }

  void test_message_didChange_whitespace() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'textDocument/didChange',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart', 'version': 2},
        'contentChanges': [
          {'text': 'var foo = 1;'},
          {'text': 'hello\nworld'},
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'textDocument': {'uri': 'file:///p0/p1/p2.dart', 'version': 2},
      'contentChanges': [
        {'text': '/* 12 characters */'},
        {'text': '/* 11 characters */'},
      ],
    });
  }

  void test_message_didOpen_scrubContent() {
    var rawContent = 'class MyClass {\n  void foo() {}\n}';
    var message = {
      'jsonrpc': '2.0',
      'method': 'textDocument/didOpen',
      'params': {
        'textDocument': {
          'uri': '{{workspaceFolder-0}}/lib/main.dart',
          'languageId': 'dart',
          'version': 1,
          'text': rawContent,
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'textDocument': {
        'uri': '{{workspaceFolder-0}}/p0/p1.dart',
        'languageId': 'dart',
        'version': 1,
        'text': '/* ${rawContent.length} characters */',
      },
    });
  }

  void test_message_documentLink() {
    // Request is processed first to register the method for ID 23.
    sanitizer.sanitizeMessage({
      'id': 23,
      'method': 'textDocument/documentLink',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 23,
      'jsonrpc': '2.0',
      'result': [
        {
          'range': {
            'start': {'line': 0, 'character': 7},
            'end': {'line': 0, 'character': 25},
          },
          'target': 'file:///test/lib/helper.dart',
        },
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'range': {
          'start': {'line': 0, 'character': 7},
          'end': {'line': 0, 'character': 25},
        },
        'target': 'file:///p0/p1/p3.dart',
      },
    ]);
  }

  void test_message_documentSymbol() {
    // Request is processed first to register the method for ID 12.
    sanitizer.sanitizeMessage({
      'id': 12,
      'method': 'textDocument/documentSymbol',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 12,
      'jsonrpc': '2.0',
      'result': [
        {
          'name': 'MyWidget',
          'kind': 5, // Class
          'detail': '(BuildContext context) -> Widget',
          'children': [
            {
              'name': 'build',
              'kind': 6, // Method
              'detail': '(BuildContext context) -> Widget',
            },
            {
              'name': 'count',
              'kind': 8, // Field
              'detail': 'int',
            },
          ],
        },
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'name': 'C1',
        'kind': 5,
        'detail': '<sanitized>',
        'children': [
          {'name': 'm1', 'kind': 6, 'detail': '<sanitized>'},
          {'name': 'v1', 'kind': 8, 'detail': '<sanitized>'},
        ],
      },
    ]);
  }

  void test_message_formatting() {
    var message = {
      'id': 24,
      'method': 'textDocument/formatting',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
        'options': {'tabSize': 2, 'insertSpaces': true},
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'textDocument': {'uri': 'file:///p0/p1/p2.dart'},
      'options': {'tabSize': 2, 'insertSpaces': true},
    });
  }

  void test_message_hover() {
    // Request is processed first to register the method for ID 13.
    sanitizer.sanitizeMessage({
      'id': 13,
      'method': 'textDocument/hover',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 13,
      'jsonrpc': '2.0',
      'result': {
        'contents': {
          'kind': 'markdown',
          'value': '```dart\nMyCustomType? myField\n```\n---\nSome secret doc comment',
        },
      },
    };

    var sanitized = sanitizer.sanitizeMessage(message);
    expect(sanitized['result'], {
      'contents': {'kind': 'markdown', 'value': '<61 chars>'},
    });
  }

  void test_message_inlayHint() {
    // Request is processed first to register the method for ID 14.
    sanitizer.sanitizeMessage({
      'id': 14,
      'method': 'textDocument/inlayHint',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
      },
    });

    var message = {
      'id': 14,
      'jsonrpc': '2.0',
      'result': [
        {'label': ': CustomReturnType'},
        {'label': 'customParam:'},
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {'label': ': a1'},
      {'label': 'a2:'},
    ]);
  }

  void test_message_legacy_updateContent_scrubContent() {
    var rawContent = 'void main() { print("hello"); }';
    var message = {
      'jsonrpc': '2.0',
      'method': 'analysis.updateContent',
      'params': {
        'files': {
          '/path/to/project/lib/main.dart': {
            'type': 'add',
            'content': rawContent,
          },
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'files': {
        '/p0/p1/p2/p3/p4.dart': {
          'type': 'add',
          'content': '/* ${rawContent.length} characters */',
        },
      },
    });
  }

  void test_message_publishClosingLabels() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'dart/textDocument/publishClosingLabels',
      'params': {
        'uri': 'file:///test/lib/main.dart',
        'labels': [
          {'label': 'MyWidget'},
          {'label': "testHelper('some value')"},
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'uri': 'file:///p0/p1/p2.dart',
      'labels': [
        {'label': 'C1'},
        {'label': 'm1(...)'},
      ],
    });
  }

  void test_message_publishDiagnostics() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'textDocument/publishDiagnostics',
      'params': {
        'uri': 'file:///test/lib/main.dart',
        'diagnostics': [
          {
            'code': 'unused_import',
            'message': 'Error in file:///test/lib/helper.dart',
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 20},
            },
          },
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'uri': 'file:///p0/p1/p2.dart',
      'diagnostics': [
        {
          'code': 'unused_import',
          'message': 'Error in file:///p0/p1/p3.dart',
          'range': {
            'start': {'line': 0, 'character': 0},
            'end': {'line': 0, 'character': 20},
          },
        },
      ],
    });
  }

  void test_message_publishFlutterOutline() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'dart/textDocument/publishFlutterOutline',
      'params': {
        'uri': 'file:///test/lib/main.dart',
        'outline': {
          'className': 'MyWidget',
          'variableName': 'myWidgetInstance',
          'label': 'MyWidget',
          'children': [
            {
              'className': 'ChildWidget',
              'variableName': 'child',
              'label': 'ChildWidget',
            },
          ],
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'uri': 'file:///p0/p1/p2.dart',
      'outline': {
        'className': 'C1',
        'variableName': 'v1',
        'label': 'C1',
        'children': [
          {'className': 'C2', 'variableName': 'v2', 'label': 'C2'},
        ],
      },
    });
  }

  void test_message_publishOutline() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'dart/textDocument/publishOutline',
      'params': {
        'uri': 'file:///test/lib/main.dart',
        'outline': {
          'element': {
            'name': 'MyClass',
            'kind': 'CLASS',
            'typeParameters': '<T>',
          },
          'children': [
            {
              'element': {
                'name': 'doSomething',
                'kind': 'METHOD',
                'returnType': 'Future<MyClass>',
                'parameters': '(String param1, int param2)',
              },
            },
            {
              'element': {
                'name': 'secretField',
                'kind': 'FIELD',
                'returnType': 'String',
              },
            },
          ],
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'uri': 'file:///p0/p1/p2.dart',
      'outline': {
        'element': {'name': 'C1', 'kind': 'CLASS', 'typeParameters': '<C2>'},
        'children': [
          {
            'element': {
              'name': 'm1',
              'kind': 'METHOD',
              'returnType': 'Future<C1>',
              'parameters': '(String a1, int a2)',
            },
          },
          {
            'element': {'name': 'v1', 'kind': 'FIELD', 'returnType': 'String'},
          },
        ],
      },
    });
  }

  void test_message_rename_and_prepareRename() {
    // 1. prepareRename request
    sanitizer.sanitizeMessage({
      'id': 1,
      'method': 'textDocument/prepareRename',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
        'position': {'line': 5, 'character': 10},
      },
    });

    // 2. prepareRename response
    var prepareRenameResponse = sanitizer.sanitizeMessage({
      'id': 1,
      'jsonrpc': '2.0',
      'result': {'placeholder': 'oldName'},
    });
    expect(prepareRenameResponse['result'], {'placeholder': 'a1'});

    // 3. rename request
    var renameRequest = sanitizer.sanitizeMessage({
      'id': 2,
      'method': 'textDocument/rename',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
        'position': {'line': 5, 'character': 10},
        'newName': 'newName',
      },
    });
    expect(renameRequest['params'], {
      'textDocument': {'uri': 'file:///p0/p1/p2.dart'},
      'position': {'line': 5, 'character': 10},
      'newName': 'a2',
    });

    // 4. rename response
    var renameResponse = sanitizer.sanitizeMessage({
      'id': 2,
      'jsonrpc': '2.0',
      'result': {
        'changes': {
          'file:///test/lib/main.dart': [
            {
              'newText': 'newName',
              'range': {
                'start': {'line': 5, 'character': 10},
                'end': {'line': 5, 'character': 17},
              },
            },
          ],
        },
      },
    });
    expect(renameResponse['result'], {
      'changes': {
        'file:///p0/p1/p2.dart': [
          {
            'newText': 'a2',
            'range': {
              'start': {'line': 5, 'character': 10},
              'end': {'line': 5, 'character': 17},
            },
          },
        ],
      },
    });
  }

  void test_message_semanticTokens_range() {
    var message = {
      'id': 25,
      'method': 'textDocument/semanticTokens/range',
      'params': {
        'textDocument': {'uri': 'file:///test/lib/main.dart'},
        'range': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 10, 'character': 0},
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'textDocument': {'uri': 'file:///p0/p1/p2.dart'},
      'range': {
        'start': {'line': 0, 'character': 0},
        'end': {'line': 10, 'character': 0},
      },
    });
  }

  void test_message_unhandled_fallbackScrubbing() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'custom/unhandledMethod',
      'params': {
        'file': 'confidential.dart',
        'fullPath': '/path/to/project/lib/main.dart',
        'count': 42,
        'nested': {
          'secret': 'confidential.dart',
          'path': 'file:///test/project/file.dart',
        },
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'file': '...',
      'fullPath': '/p0/p1/p2/p3/p4.dart',
      'count': 42,
      'nested': {'secret': '...', 'path': 'file:///p5/p2/p6.dart'},
    });
  }

  void test_message_workspace_executeCommand() {
    var message = {
      'jsonrpc': '2.0',
      'method': 'workspace/executeCommand',
      'params': {
        'command': 'dart.edit.organizeImports',
        'arguments': [
          {'path': 'file:///test/lib/main.dart', 'autoTriggered': true},
        ],
      },
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['params'], {
      'command': 'dart.edit.organizeImports',
      'arguments': [
        {'path': 'file:///p0/p1/p2.dart', 'autoTriggered': true},
      ],
    });
  }

  void test_message_workspaceConfiguration() {
    var message = {
      'id': 3,
      'jsonrpc': '2.0',
      'result': [
        {
          'sdkPath':
              '/Users/user/code/dart-sdk/sdk/xcodebuild/ReleaseARM64/dart-sdk',
          'flutterSdkPath': '/Users/user/code/flutter',
          'analyzerInstrumentationLogFile':
              '/Users/user/analyzerInstrumentation.txt',
          'devToolsLogFile': '/Users/user/devtools-log.txt',
          'analysisExcludedFolders': ['tool/flutter-sdk'],
        },
      ],
    };

    // Request is processed first to register the method for ID 3.
    sanitizer.sanitizeMessage({
      'id': 3,
      'method': 'workspace/configuration',
      'params': {'items': []},
    });

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'sdkPath': '/p0/p1/p2/p3/p4/p5/p6/p3',
        'flutterSdkPath': '/p0/p1/p2/p7',
        'analyzerInstrumentationLogFile': '/p0/p1/p8',
        'devToolsLogFile': '/p0/p1/p9',
        'analysisExcludedFolders': ['p10/p11'],
      },
    ]);
  }

  void test_message_workspaceConfiguration_nonPathValues() {
    // Request is processed first to register the method for ID 4.
    sanitizer.sanitizeMessage({
      'id': 4,
      'method': 'workspace/configuration',
      'params': {'items': []},
    });

    var message = {
      'id': 4,
      'jsonrpc': '2.0',
      'result': [
        {
          'enableFeature': true,
          'targetFile': 'confidential.dart',
          'otherSettings': ['confidential.dart', '/valid/path/file.dart'],
        },
      ],
    };

    var result = sanitizer.sanitizeMessage(message);
    expect(result['result'], [
      {
        'enableFeature': true,
        'targetFile': '...',
        'otherSettings': ['...', '/p0/p1/p2.dart'],
      },
    ]);
  }

  void test_sanitize_indicatorEntry() {
    var entries = [
      {key.kind: EntryKind.info.name, key.message: 'Test message'},
    ];

    var result = sanitizer.sanitize(entries);
    expect(result, [
      LogSanitizer.sanitizedIndicator,
      {key.kind: EntryKind.info.name, key.message: 'Test message'},
    ]);
  }

  void test_sanitizeIdentifier_classesAndMethods() {
    expect(
      sanitizer.sanitizeIdentifier('Foo', kind: IdentifierKind.typeDeclaration),
      'C1',
    );
    expect(
      sanitizer.sanitizeIdentifier('Bar', kind: IdentifierKind.typeDeclaration),
      'C2',
    );
    expect(sanitizer.sanitizeIdentifier('Foo'), 'C1');
    // Classes can also be lowercase:
    expect(
      sanitizer.sanitizeIdentifier(
        'myClass',
        kind: IdentifierKind.typeDeclaration,
      ),
      'C3',
    );

    expect(
      sanitizer.sanitizeIdentifier('bar', kind: IdentifierKind.method),
      'm1',
    );
    expect(
      sanitizer.sanitizeIdentifier('baz', kind: IdentifierKind.method),
      'm2',
    );
    expect(sanitizer.sanitizeIdentifier('bar'), 'm1');

    // Variables/fields can also be uppercase:
    expect(
      sanitizer.sanitizeIdentifier('MY_CONST', kind: IdentifierKind.variable),
      'v1',
    );
    expect(sanitizer.sanitizeIdentifier('MY_CONST'), 'v1');
  }

  void test_sanitizeIdentifier_compound() {
    // Test the user's specific example: 'Foo.bar' and 'Foo.baz' -> 'C1.m1' and 'C1.m2'
    expect(sanitizer.sanitizeIdentifier('Foo.bar'), 'C1.m1');
    expect(sanitizer.sanitizeIdentifier('Foo.baz'), 'C1.m2');
  }

  void test_sanitizeIdentifier_keywordsAndCoreTypes() {
    expect(sanitizer.sanitizeIdentifier('void'), 'void');
    expect(sanitizer.sanitizeIdentifier('dynamic'), 'dynamic');
    expect(sanitizer.sanitizeIdentifier('String'), 'String');
    expect(sanitizer.sanitizeIdentifier('int'), 'int');
    expect(sanitizer.sanitizeIdentifier('bool'), 'bool');
    expect(sanitizer.sanitizeIdentifier('Future'), 'Future');
    expect(sanitizer.sanitizeIdentifier('List'), 'List');
    expect(sanitizer.sanitizeIdentifier('Map'), 'Map');
    expect(sanitizer.sanitizeIdentifier('class'), 'class');
    expect(sanitizer.sanitizeIdentifier('final'), 'final');
  }

  void test_sanitizePath_consistentSegments() {
    // Test user's specific example: 'foo/bar/baz.dart' and 'foo/bar/quux.dart'
    // -> 'p0/p1/p2.dart' and 'p0/p1/p3.dart'
    expect(sanitizer.sanitizePath('foo/bar/baz.dart'), 'p0/p1/p2.dart');
    expect(sanitizer.sanitizePath('foo/bar/quux.dart'), 'p0/p1/p3.dart');
  }

  void test_sanitizePath_dartUri() {
    expect(sanitizer.sanitizePath('dart:core'), 'dart:core');
    expect(sanitizer.sanitizePath('dart:async'), 'dart:async');
  }

  void test_sanitizePath_fileSuffixes() {
    // Preserves .dart and .yaml
    expect(sanitizer.sanitizePath('a/c.yaml'), 'p0/p1.yaml');
    expect(sanitizer.sanitizePath('a/b.dart'), 'p0/p2.dart');

    // Scraps all other file extensions
    expect(sanitizer.sanitizePath('foo.js'), 'p3');
    expect(sanitizer.sanitizePath('bar.xml'), 'p4');
    expect(sanitizer.sanitizePath('a/d.txt'), 'p0/p5');
    expect(sanitizer.sanitizePath('a/e.png'), 'p0/p6');
    expect(sanitizer.sanitizePath('a/f.json'), 'p0/p7');
  }

  void test_sanitizePath_fileUri() {
    expect(
      sanitizer.sanitizePath('file:///Users/user/project/lib/main.dart'),
      'file:///p0/p1/p2/p3/p4.dart',
    );
  }

  void test_sanitizePath_packageUri() {
    expect(
      sanitizer.sanitizePath('package:my_package/src/helper.dart'),
      'package:p0/p1/p2.dart',
    );
  }

  void test_sanitizePath_placeholders() {
    expect(
      sanitizer.sanitizePath(
        '{{workspaceFolder-0}}/packages/devtools/lib/main.dart',
      ),
      '{{workspaceFolder-0}}/p0/p1/p2/p3.dart',
    );
    expect(
      sanitizer.sanitizePath('{{dartSdkRoot}}/lib/core/core.dart'),
      '{{dartSdkRoot}}/p2/p4/p4.dart',
    );
    expect(
      sanitizer.sanitizePath('file:///{{dartSdkRoot}}/bin/dart'),
      'file:///{{dartSdkRoot}}/p5/p6',
    );
  }

  void test_sanitizePath_relative() {
    expect(sanitizer.sanitizePath('../foo/bar.dart'), '../p0/p1.dart');
    expect(sanitizer.sanitizePath('./foo/baz.dart'), './p0/p2.dart');
  }

  void test_sanitizePath_windows() {
    expect(
      sanitizer.sanitizePath(r'C:\Users\user\project\lib\main.dart'),
      r'C:\p0\p1\p2\p3\p4.dart',
    );
  }

  void test_sanitizeTypeString() {
    expect(
      sanitizer.sanitizeTypeString('(BuildContext context) -> Widget'),
      '(a1 a2) -> a3',
    );
    expect(
      sanitizer.sanitizeTypeString('Map<String, UserClass>'),
      'Map<String, a4>',
    );
    expect(sanitizer.sanitizeTypeString('List<CustomItem>?'), 'List<a5>?');
  }
}
