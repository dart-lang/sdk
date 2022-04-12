// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/snippets/dart/dart_snippet_producers.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_snippet_producers.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'completion.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTest);
    defineReflectiveTests(DartSnippetCompletionTest);
    defineReflectiveTests(FlutterSnippetCompletionTest);
    defineReflectiveTests(
        FlutterSnippetCompletionWithLatestLanguageVersionTest);
    defineReflectiveTests(CompletionTestWithNullSafetyTest);
  });
}

@reflectiveTest
class CompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  Future<void> checkCompleteFunctionCallInsertText(
      String content, String completion,
      {required String? insertText, InsertTextFormat? insertTextFormat}) async {
    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'completeFunctionCalls': true},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere(
      (c) => c.label == completion,
      orElse: () =>
          throw 'Did not find $completion in ${res.map((r) => r.label).toList()}',
    );

    expect(item.insertTextFormat, equals(insertTextFormat));
    expect(item.insertText, equals(insertText));

    final textEdit = toTextEdit(item.textEdit!);
    // newText in the edit will always be set, so if insertText is null we need
    // fall back to item.label for the expected value.
    expect(textEdit.newText, equals(item.insertText ?? item.label));
    expect(textEdit.range, equals(rangeFromMarkers(content)));
  }

  void expectAutoImportCompletion(List<CompletionItem> items, String file) {
    expect(
      items.singleWhereOrNull(
          (c) => c.detail?.contains("Auto import from '$file'") ?? false),
      isNotNull,
    );
  }

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      projectFolderPath,
      flutter: true,
    );
  }

  Future<void> test_comment() async {
    final content = '''
    // foo ^
    void f() {}
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res, isEmpty);
  }

  Future<void> test_comment_endOfFile_withNewline() async {
    // Checks for a previous bug where invoking completion inside a comment
    // at the end of a file would return results.
    final content = '''
    // foo ^
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res, isEmpty);
  }

  Future<void> test_comment_endOfFile_withoutNewline() async {
    // Checks for a previous bug where invoking completion inside a comment
    // at the very end of a file with no trailing newline would return results.
    final content = '// foo ^';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res, isEmpty);
  }

  Future<void> test_commitCharacter_completionItem() async {
    await provideConfig(
      () => initialize(
        textDocumentCapabilities:
            withAllSupportedTextDocumentDynamicRegistrations(
                emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'previewCommitCharacters': true},
    );

    final content = '''
void f() {
  pri^
}
    ''';

    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final print = res.singleWhere((c) => c.label == 'print(…)');
    expect(print.commitCharacters, equals(dartCompletionCommitCharacters));
  }

  Future<void> test_commitCharacter_config() async {
    final registrations = <Registration>[];
    // Provide empty config and collect dynamic registrations during
    // initialization.
    await provideConfig(
      () => monitorDynamicRegistrations(
        registrations,
        () => initialize(
            textDocumentCapabilities:
                withAllSupportedTextDocumentDynamicRegistrations(
                    emptyTextDocumentClientCapabilities),
            workspaceCapabilities:
                withDidChangeConfigurationDynamicRegistration(
                    withConfigurationSupport(
                        emptyWorkspaceClientCapabilities))),
      ),
      {},
    );

    Registration registration(Method method) =>
        registrationForDart(registrations, method);

    // By default, there should be no commit characters.
    var reg = registration(Method.textDocument_completion);
    var options = CompletionRegistrationOptions.fromJson(
        reg.registerOptions as Map<String, Object?>);
    expect(options.allCommitCharacters, isNull);

    // When we change config, we should get a re-registration (unregister then
    // register) for completion which now includes the commit characters.
    await monitorDynamicReregistration(
        registrations, () => updateConfig({'previewCommitCharacters': true}));
    reg = registration(Method.textDocument_completion);
    options = CompletionRegistrationOptions.fromJson(
        reg.registerOptions as Map<String, Object?>);
    expect(options.allCommitCharacters, equals(dartCompletionCommitCharacters));
  }

  Future<void> test_completeFunctionCalls_constructor() =>
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          Aaaaa(int a);
        }
        void f(int aaa) {
          var a = new [[Aaa^]]
        }
        ''',
        'Aaaaa(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        insertText: r'Aaaaa(${0:a})',
      );

  Future<void> test_completeFunctionCalls_escapesDollarArgs() =>
      checkCompleteFunctionCallInsertText(
        r'''
        int myFunction(String a$a, int b, {String c}) {
          var a = [[myFu^]]
        }
        ''',
        'myFunction(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        // The dollar should have been escaped.
        insertText: r'myFunction(${1:a\$a}, ${2:b})',
      );

  Future<void> test_completeFunctionCalls_escapesDollarName() =>
      checkCompleteFunctionCallInsertText(
        r'''
        int myFunc$tion(String a, int b, {String c}) {
          var a = [[myFu^]]
        }
        ''',
        r'myFunc$tion(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        // The dollar should have been escaped.
        insertText: r'myFunc\$tion(${1:a}, ${2:b})',
      );

  Future<void> test_completeFunctionCalls_existingArgList_constructor() =>
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          Aaaaa(int a);
        }
        void f(int aaa) {
          var a = new [[Aaa^]]()
        }
        ''',
        'Aaaaa(…)',
        insertText: 'Aaaaa',
      );

  Future<void> test_completeFunctionCalls_existingArgList_expression() =>
      checkCompleteFunctionCallInsertText(
        '''
        int myFunction(String a, int b, {String c}) {
          var a = [[myFu^]]()
        }
        ''',
        'myFunction(…)',
        insertText: 'myFunction',
      );

  Future<void> test_completeFunctionCalls_existingArgList_member_noPrefix() =>
      // https://github.com/Dart-Code/Dart-Code/issues/3672
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          static foo(int a) {}
        }
        void f() {
          Aaaaa.[[^]]()
        }
        ''',
        'foo(…)',
        insertText: 'foo',
      );

  Future<void> test_completeFunctionCalls_existingArgList_namedConstructor() =>
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          Aaaaa.foo(int a);
        }
        void f() {
          var a = new Aaaaa.[[foo^]]()
        }
        ''',
        'foo(…)',
        insertText: 'foo',
      );

  Future<void> test_completeFunctionCalls_existingArgList_statement() =>
      checkCompleteFunctionCallInsertText(
        '''
        void f(int a) {
          [[f^]]()
        }
        ''',
        'f(…)',
        insertText: 'f',
      );

  Future<void> test_completeFunctionCalls_existingArgList_suggestionSets() =>
      checkCompleteFunctionCallInsertText(
        '''
        void f(int a) {
          [[pri^]]()
        }
        ''',
        'print(…)',
        insertText: 'print',
      );

  Future<void> test_completeFunctionCalls_existingPartialArgList() =>
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          Aaaaa(int a);
        }
        void f(int aaa) {
          var a = new [[Aaa^]](
        }
        ''',
        'Aaaaa(…)',
        insertText: 'Aaaaa',
      );

  Future<void> test_completeFunctionCalls_expression() =>
      checkCompleteFunctionCallInsertText(
        '''
        int myFunction(String a, int b, {String c}) {
          var a = [[myFu^]]
        }
        ''',
        'myFunction(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        insertText: r'myFunction(${1:a}, ${2:b})',
      );

  Future<void> test_completeFunctionCalls_flutterSetState() async {
    // Flutter's setState method has special handling inside SuggestionBuilder
    // that already adds in a selection (which overlaps with completeFunctionCalls).
    // Ensure we don't end up with two sets of parens/placeholders in this case.
    final content = '''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    [[setSt^]]
    return Container();
  }
}
    ''';

    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'completeFunctionCalls': true},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label.startsWith('setState('));

    // Usually the label would be "setState(…)" but here it's slightly different
    // to indicate a full statement is being inserted.
    expect(item.label, equals('setState(() {});'));

    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, equals('setState(() {\n      \$0\n    });'));
    final textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(item.insertText));
    expect(textEdit.range, equals(rangeFromMarkers(content)));
  }

  Future<void> test_completeFunctionCalls_namedConstructor() =>
      checkCompleteFunctionCallInsertText(
        '''
        class Aaaaa {
          Aaaaa.foo(int a);
        }
        void f() {
          var a = new Aaaaa.[[foo^]]
        }
        ''',
        'foo(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        insertText: r'foo(${0:a})',
      );

  Future<void> test_completeFunctionCalls_noParameters() async {
    final content = '''
    void myFunction() {}

    void f() {
      [[myFu^]]
    }
    ''';

    await checkCompleteFunctionCallInsertText(
      content,
      'myFunction()',
      // With no params, we don't put a tab stop inside the parens. This results
      // in the insertText being the same as the label, which means it will be
      // set to null so that it falls back without needing to repeat the value.
      insertText: null,
      insertTextFormat: InsertTextFormat.Snippet,
    );
  }

  Future<void> test_completeFunctionCalls_optionalParameters() async {
    final content = '''
    void myFunction({int a}) {}

    void f() {
      [[myFu^]]
    }
    ''';

    await checkCompleteFunctionCallInsertText(
      content,
      'myFunction(…)',
      // With optional params, there should still be parens/tab stop inside.
      insertText: r'myFunction($0)',
      insertTextFormat: InsertTextFormat.Snippet,
    );
  }

  Future<void> test_completeFunctionCalls_show() async {
    final content = '''
    import 'dart:math' show mi^
    ''';

    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'completeFunctionCalls': true},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'min(…)');
    // The insert text should be a simple string with no parens/args and
    // no need for snippets.
    expect(item.insertTextFormat, isNull);
    expect(item.insertText, equals(r'min'));
    final textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(item.insertText));
  }

  Future<void> test_completeFunctionCalls_statement() =>
      checkCompleteFunctionCallInsertText(
        '''
        void f(int a) {
          [[f^]]
        }
        ''',
        'f(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        insertText: r'f(${0:a})',
      );

  Future<void> test_completeFunctionCalls_suggestionSets() =>
      checkCompleteFunctionCallInsertText(
        '''
        void f(int a) {
          [[pri^]]
        }
        ''',
        'print(…)',
        insertTextFormat: InsertTextFormat.Snippet,
        insertText: r'print(${0:object})',
      );

  Future<void> test_completionKinds_default() async {
    newFile2(join(projectFolderPath, 'file.dart'), '');
    newFolder(join(projectFolderPath, 'folder'));

    final content = "import '^';";

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final file = res.singleWhere((c) => c.label == 'file.dart');
    final folder = res.singleWhere((c) => c.label == 'folder/');
    final builtin = res.singleWhere((c) => c.label == 'dart:core');
    // Default capabilities include File + Module but not Folder.
    expect(file.kind, equals(CompletionItemKind.File));
    // We fall back to Module if Folder isn't supported.
    expect(folder.kind, equals(CompletionItemKind.Module));
    expect(builtin.kind, equals(CompletionItemKind.Module));
  }

  Future<void> test_completionKinds_imports() async {
    final content = "import '^';";

    // Tell the server we support some specific CompletionItemKinds.
    await initialize(
      textDocumentCapabilities: withCompletionItemKinds(
        emptyTextDocumentClientCapabilities,
        [
          CompletionItemKind.File,
          CompletionItemKind.Folder,
          CompletionItemKind.Module,
        ],
      ),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final file = res.singleWhere((c) => c.label == 'file.dart');
    final folder = res.singleWhere((c) => c.label == 'folder/');
    final builtin = res.singleWhere((c) => c.label == 'dart:core');
    expect(file.kind, equals(CompletionItemKind.File));
    expect(folder.kind, equals(CompletionItemKind.Folder));
    expect(builtin.kind, equals(CompletionItemKind.Module));
  }

  Future<void> test_completionKinds_supportedSubset() async {
    final content = '''
    class MyClass {
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    // Tell the server we only support the Field CompletionItemKind.
    await initialize(
      textDocumentCapabilities: withCompletionItemKinds(
          emptyTextDocumentClientCapabilities, [CompletionItemKind.Field]),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final kinds = res.map((item) => item.kind).toList();

    // Ensure we only get nulls or Fields (the sample code contains Classes).
    expect(
      kinds,
      everyElement(anyOf(isNull, equals(CompletionItemKind.Field))),
    );
  }

  Future<void> test_completionTrigger_brace_block() async {
    // Brace should not trigger completion if a normal code block.
    final content = r'''
    main () {^}
    ''';
    await _checkResultsForTriggerCharacters(content, ['{'], isEmpty);
  }

  Future<void>
      test_completionTrigger_brace_interpolatedStringExpression() async {
    // Brace should trigger completion if at the start of an interpolated expression
    final content = r'''
    var a = '${^';
    ''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isNotEmpty);
  }

  Future<void> test_completionTrigger_brace_rawString() async {
    // Brace should not trigger completion if in a raw string.
    final content = r'''
    var a = r'${^';
    ''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isEmpty);
  }

  Future<void> test_completionTrigger_brace_string() async {
    // Brace should not trigger completion if not at the start of an interpolated
    // expression.
    final content = r'''
    var a = '{^';
    ''';
    await _checkResultsForTriggerCharacters(content, [r'{'], isEmpty);
  }

  Future<void> test_completionTrigger_quotes_endingString() async {
    // Completion triggered by a quote ending a string should not return results.
    final content = "foo(''^);";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_quotes_startingImport() async {
    // Completion triggered by a quote for import should return results.
    final content = "import '^'";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isNotEmpty);
  }

  Future<void> test_completionTrigger_quotes_startingString() async {
    // Completion triggered by a quote for normal string should not return results.
    final content = "foo('^');";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_quotes_terminatingImport() async {
    // Completion triggered by a quote ending an import should not return results.
    final content = "import ''^";
    await _checkResultsForTriggerCharacters(content, ["'", '"'], isEmpty);
  }

  Future<void> test_completionTrigger_slash_directivePath() async {
    // Slashes should trigger completion when typing in directive paths, eg.
    // after typing 'package:foo/' completion should give the next folder segments.
    final content = r'''
    import 'package:test/^';
    ''';
    await _checkResultsForTriggerCharacters(content, [r'/'], isNotEmpty);
  }

  Future<void> test_completionTrigger_slash_divide() async {
    // Slashes should not trigger completion when typing in a normal expression.
    final content = r'''
    var a = 1 /^
    ''';
    await _checkResultsForTriggerCharacters(content, [r'/'], isEmpty);
  }

  Future<void> test_completionTriggerKinds_invalidParams() async {
    await initialize();

    final invalidTriggerKind = CompletionTriggerKind.fromJson(-1);
    final request = getCompletion(
      mainFileUri,
      Position(line: 0, character: 0),
      context: CompletionContext(
          triggerKind: invalidTriggerKind, triggerCharacter: 'A'),
    );

    await expectLater(
        request, throwsA(isResponseError(ErrorCodes.InvalidParams)));
  }

  Future<void> test_filterTextNotIncludeAdditionalText() async {
    // Some completions (eg. overrides) have additional text that is not part
    // of the label. That text should _not_ appear in filterText as it will
    // affect the editors relevance ranking as the user types.
    // https://github.com/dart-lang/sdk/issues/45157
    final content = '''
    abstract class Person {
      String get name;
    }

    class Student extends Person {
      nam^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhereOrNull((c) => c.label.startsWith('name =>'));
    expect(item, isNotNull);
    expect(item!.label, equals('name => …'));
    expect(item.filterText, isNull); // Falls back to label
    expect(item.insertText, equals('''@override
  // TODO: implement name
  String get name => throw UnimplementedError();'''));
  }

  Future<void> test_fromPlugin_dartFile() async {
    final content = '''
    void f() {
      var x = '';
      print(^);
    }
    ''';

    final pluginResult = plugin.CompletionGetSuggestionsResult(
      content.indexOf('^'),
      0,
      [
        plugin.CompletionSuggestion(
          plugin.CompletionSuggestionKind.INVOCATION,
          100,
          'x.toUpperCase()',
          -1,
          -1,
          false,
          false,
        ),
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final fromServer = res.singleWhere((c) => c.label == 'x');
    final fromPlugin = res.singleWhere((c) => c.label == 'x.toUpperCase()');

    expect(fromServer.kind, equals(CompletionItemKind.Variable));
    expect(fromPlugin.kind, equals(CompletionItemKind.Method));
  }

  Future<void> test_fromPlugin_nonDartFile() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    final pluginAnalyzedFileUri = Uri.file(pluginAnalyzedFilePath);
    final content = '''
    CREATE TABLE foo (
      id INTEGER NOT NULL PRIMARY KEY
    );

    query: SELECT ^ FROM foo;
    ''';

    final pluginResult = plugin.CompletionGetSuggestionsResult(
      content.indexOf('^'),
      0,
      [
        plugin.CompletionSuggestion(
          plugin.CompletionSuggestionKind.IDENTIFIER,
          100,
          'id',
          -1,
          -1,
          false,
          false,
        ),
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    await initialize();
    await openFile(pluginAnalyzedFileUri, withoutMarkers(content));
    final res =
        await getCompletion(pluginAnalyzedFileUri, positionFromMarker(content));

    expect(res, hasLength(1));
    final suggestion = res.single;

    expect(suggestion.kind, CompletionItemKind.Variable);
    expect(suggestion.label, equals('id'));
  }

  Future<void> test_fromPlugin_tooSlow() async {
    final content = '''
    void f() {
      var x = '';
      print(^);
    }
    ''';

    final pluginResult = plugin.CompletionGetSuggestionsResult(
      content.indexOf('^'),
      0,
      [
        plugin.CompletionSuggestion(
          plugin.CompletionSuggestionKind.INVOCATION,
          100,
          'x.toUpperCase()',
          -1,
          -1,
          false,
          false,
        ),
      ],
    );
    configureTestPlugin(
      respondWith: pluginResult,
      // Don't respond within an acceptable time
      respondAfter: Duration(seconds: 1),
    );

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final fromServer = res.singleWhere((c) => c.label == 'x');
    final fromPlugin =
        res.singleWhereOrNull((c) => c.label == 'x.toUpperCase()');

    // Server results should still be included.
    expect(fromServer.kind, equals(CompletionItemKind.Variable));
    // Plugin results are not because they didn't arrive in time.
    expect(fromPlugin, isNull);
  }

  Future<void> test_gettersAndSetters() async {
    final content = '''
    class MyClass {
      String get justGetter => '';
      String set justSetter(String value) {}
      String get getterAndSetter => '';
      String set getterAndSetter(String value) {}
    }

    void f() {
      MyClass a;
      a.^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final getter = res.singleWhere((c) => c.label == 'justGetter');
    final setter = res.singleWhere((c) => c.label == 'justSetter');
    final both = res.singleWhere((c) => c.label == 'getterAndSetter');
    expect(getter.detail, equals('String'));
    expect(setter.detail, equals('String'));
    expect(both.detail, equals('String'));
    for (var item in [getter, setter, both]) {
      expect(item.kind, equals(CompletionItemKind.Property));
    }
  }

  Future<void> test_insertReplaceRanges() async {
    final content = '''
    class MyClass {
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^def
    }
    ''';

    await initialize(
      textDocumentCapabilities: withCompletionItemInsertReplaceSupport(
          emptyTextDocumentClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    // When using the replacement range, we should get exactly the symbol
    // we expect.
    final replaced = applyTextEdits(
      withoutMarkers(content),
      [textEditForReplace(item.textEdit!)],
    );
    expect(replaced, contains('a.abcdefghij\n'));
    // When using the insert range, we should retain what was after the caret
    // ("def" in this case).
    final inserted = applyTextEdits(
      withoutMarkers(content),
      [textEditForInsert(item.textEdit!)],
    );
    expect(inserted, contains('a.abcdefghijdef\n'));
  }

  Future<void> test_insertTextMode_multiline() async {
    final content = '''
    import 'package:flutter/material.dart';

    class _MyWidgetState extends State<MyWidget> {
      @override
      Widget build(BuildContext context) {
        [[setSt^]]
        return Container();
      }
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemInsertTextModeSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label.startsWith('setState'));

    // Multiline completions should always set insertTextMode.asIs.
    expect(item.insertText, contains('\n'));
    expect(item.insertTextMode, equals(InsertTextMode.asIs));
  }

  Future<void> test_insertTextMode_singleLine() async {
    final content = '''
    void foo() {
      ^
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemInsertTextModeSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label.startsWith('foo'));

    // Single line completions should never set insertTextMode.asIs to
    // avoid bloating payload size where it wouldn't matter.
    expect(item.insertText, isNot(contains('\n')));
    expect(item.insertTextMode, isNull);
  }

  Future<void> test_insideString() async {
    final content = '''
    var a = "This is ^a test"
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res, isEmpty);
  }

  Future<void> test_isDeprecated_notSupported() async {
    final content = '''
    class MyClass {
      @deprecated
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.deprecated, isNull);
    // If the does not say it supports the deprecated flag, we should show
    // '(deprecated)' in the details.
    expect(item.detail!.toLowerCase(), contains('deprecated'));
  }

  Future<void> test_isDeprecated_supportedFlag() async {
    final content = '''
    class MyClass {
      @deprecated
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemDeprecatedFlagSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.deprecated, isTrue);
    // If the client says it supports the deprecated flag, we should not show
    // deprecated in the details.
    expect(item.detail, isNot(contains('deprecated')));
  }

  Future<void> test_isDeprecated_supportedTag() async {
    final content = '''
    class MyClass {
      @deprecated
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemTagSupport(
            emptyTextDocumentClientCapabilities,
            [CompletionItemTag.Deprecated]));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.tags, contains(CompletionItemTag.Deprecated));
    // If the client says it supports the deprecated tag, we should not show
    // deprecated in the details.
    expect(item.detail, isNot(contains('deprecated')));
  }

  Future<void> test_isIncomplete_falseIfAllIncluded() async {
    final content = '''
import 'a.dart';
void f() {
  A a = A();
  a.^
}
    ''';

    // Create a class with fields aaa1 to aaa500 in the other file.
    newFile2(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        'class A {',
        for (var i = 1; i <= 500; i++) 'String get aaa$i => "";',
        '}',
      ].join('\n'),
    );

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res =
        await getCompletionList(mainFileUri, positionFromMarker(content));

    // Expect everything (hashCode etc. will take it over 500).
    expect(res.items, hasLength(greaterThanOrEqualTo(500)));
    expect(res.isIncomplete, isFalse);
  }

  Future<void> test_isIncomplete_trueIfNotAllIncluded() async {
    final content = '''
import 'a.dart';
void f() {
  A a = A();
  a.^
}
    ''';

    // Create a class with fields aaa1 to aaa500 in the other file.
    newFile2(
      join(projectFolderPath, 'lib', 'a.dart'),
      [
        'class A {',
        for (var i = 1; i <= 500; i++) '  String get aaa$i => "";',
        '  String get aaa => "";',
        '}',
      ].join('\n'),
    );

    final initialAnalysis = waitForAnalysisComplete();
    await provideConfig(
      () => initialize(
          workspaceCapabilities: withApplyEditSupport(
              withConfigurationSupport(emptyWorkspaceClientCapabilities))),
      {'maxCompletionItems': 200},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res =
        await getCompletionList(mainFileUri, positionFromMarker(content));

    // Should be capped at 200 and marked as incomplete.
    expect(res.items, hasLength(200));
    expect(res.isIncomplete, isTrue);

    // Also ensure 'aaa' is included, since relevance sorting should have
    // put it at the top.
    expect(res.items.map((item) => item.label).contains('aaa'), isTrue);
  }

  Future<void> test_namedArg_insertReplaceRanges() async {
    /// Helper to check multiple completions in the same template file.
    Future<void> check(
      String code,
      String expectedLabel, {
      required String expectedReplace,
      required String expectedInsert,
    }) async {
      final content = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$code
void f() { }
''';
      final expectedReplaced = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$expectedReplace
void f() { }
''';
      final expectedInserted = '''
class A { const A({int argOne, int argTwo, String argThree}); }
final varOne = '';
$expectedInsert
void f() { }
''';

      await verifyCompletions(
        mainFileUri,
        content,
        expectCompletions: [expectedLabel],
        applyEditsFor: expectedLabel,
        verifyInsertReplaceRanges: true,
        expectedContent: expectedReplaced,
        expectedContentIfInserting: expectedInserted,
      );
    }

    // When at the start of the identifier, it will be set as the replacement
    // range so we don't expect the ': ,'
    await check(
      '@A(^argOne: 1)',
      'argTwo',
      expectedReplace: '@A(argTwo: 1)',
      expectedInsert: '@A(argTwoargOne: 1)',
    );

    // When adding a name to an existing value, it should always insert.
    await check(
      '@A(^1)',
      'argOne: ',
      expectedReplace: '@A(argOne: 1)',
      expectedInsert: '@A(argOne: 1)',
    );

    // When adding a name to an existing variable, it should always insert.
    await check(
      '@A(argOne: 1, ^varOne)',
      'argTwo: ',
      expectedReplace: '@A(argOne: 1, argTwo: varOne)',
      expectedInsert: '@A(argOne: 1, argTwo: varOne)',
    );

    // // Inside the identifier also should be expected to replace.
    await check(
      '@A(arg^One: 1)',
      'argTwo',
      expectedReplace: '@A(argTwo: 1)',
      expectedInsert: '@A(argTwoOne: 1)',
    );

    // If there's a space, there's no replacement range so we should still get
    // the colon/comma since this is always an insert (and both operations will
    // produce the same text).
    await check(
      '@A(^ argOne: 1)',
      'argTwo: ',
      expectedReplace: '@A(argTwo: ^, argOne: 1)',
      expectedInsert: '@A(argTwo: ^, argOne: 1)',
    );

    // Partially typed names in front of values (that aren't considered part of
    // the same identifier) should also suggest name labels.
    await check(
      '''@A(argOne: 1, argTh^'Foo')''',
      'argThree: ',
      expectedReplace: '''@A(argOne: 1, argThree: 'Foo')''',
      expectedInsert: '''@A(argOne: 1, argThree: 'Foo')''',
    );
  }

  Future<void> test_namedArg_offsetBeforeCompletionTarget() async {
    // This test checks for a previous bug where the completion target was a
    // symbol far after the cursor offset (`aaaa` here) and caused the whole
    // identifier to be used as the `targetPrefix` which would filter out
    // other symbol.
    // https://github.com/Dart-Code/Dart-Code/issues/2672#issuecomment-666085575
    final content = '''
    void f() {
      myFunction(
        ^
        aaaa: '',
      );
    }

    void myFunction({String aaaa, String aaab, String aaac}) {}
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'aaab: '), isTrue);
  }

  Future<void> test_namedArg_plainText() async {
    final content = '''
    class A { const A({int one}); }
    @A(^)
    void f() { }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'one: '), isTrue);
    final item = res.singleWhere((c) => c.label == 'one: ');
    expect(item.insertTextFormat,
        anyOf(equals(InsertTextFormat.PlainText), isNull));
    expect(item.insertText, anyOf(equals('test'), isNull));
    final updated = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(item.textEdit!)],
    );
    expect(updated, contains('one: '));
  }

  Future<void> test_namedArg_snippetStringSelection_endOfString() async {
    final content = '''
    class A { const A({int one}); }
    @A(^)
    void f() { }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'one: '), isTrue);
    final item = res.singleWhere((c) => c.label == 'one: ');
    // As the selection is the end of the string, there's no need for a snippet
    // here. Since the insert text is also the same as the label, it does not
    // need to be provided.
    expect(item.insertTextFormat, isNull);
    expect(item.insertText, isNull);
    final textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals('one: '));
    expect(
      textEdit.range,
      equals(Range(
          start: positionFromMarker(content),
          end: positionFromMarker(content))),
    );
  }

  Future<void>
      test_namedArgTrailing_snippetStringSelection_insideString() async {
    final content = '''
    void f({int one, int two}) {
      f(
        ^
        two: 2,
      );
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'one: '), isTrue);
    final item = res.singleWhere((c) => c.label == 'one: ');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholder.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, equals(r'one: $0,'));
    final textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(r'one: $0,'));
    expect(
      textEdit.range,
      equals(Range(
          start: positionFromMarker(content),
          end: positionFromMarker(content))),
    );
  }

  Future<void> test_nonAnalyzedFile() async {
    final readmeFilePath = convertPath(join(projectFolderPath, 'README.md'));
    newFile2(readmeFilePath, '');
    await initialize();

    final res = await getCompletion(Uri.file(readmeFilePath), startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_parensNotInFilterTextInsertText() async {
    final content = '''
    class MyClass {}

    void f() {
      MyClass a = new MyCla^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'MyClass()'), isTrue);
    final item = res.singleWhere((c) => c.label == 'MyClass()');
    expect(item.filterText, equals('MyClass'));
    expect(item.insertText, equals('MyClass'));
  }

  Future<void> test_plainText() async {
    final content = '''
    class MyClass {
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.insertTextFormat,
        anyOf(equals(InsertTextFormat.PlainText), isNull));
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    final updated = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(item.textEdit!)],
    );
    expect(updated, contains('a.abcdefghij'));
  }

  Future<void> test_prefixFilter_endOfSymbol() async {
    final content = '''
    class UniqueNamedClassForLspOne {}
    class UniqueNamedClassForLspTwo {}
    class UniqueNamedClassForLspThree {}

    void f() {
      // Should match only Two and Three
      UniqueNamedClassForLspT^
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isFalse);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_prefixFilter_midSymbol() async {
    final content = '''
    class UniqueNamedClassForLspOne {}
    class UniqueNamedClassForLspTwo {}
    class UniqueNamedClassForLspThree {}

    void f() {
      // Should match only Two and Three
      UniqueNamedClassForLspT^hree
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isFalse);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_prefixFilter_startOfSymbol() async {
    final content = '''
    class UniqueNamedClassForLspOne {}
    class UniqueNamedClassForLspTwo {}
    class UniqueNamedClassForLspThree {}

    void f() {
      // Should match all three
      ^UniqueNamedClassForLspT
    }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspOne'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspTwo'), isTrue);
    expect(res.any((c) => c.label == 'UniqueNamedClassForLspThree'), isTrue);
  }

  Future<void> test_unimportedSymbols() async {
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      '''
      /// This class is in another file.
      class InOtherFile {}
      ''',
    );

    final content = '''
void f() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Find the completion for the class in the other file.
    final completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);

    // Expect no docs or text edit, since these are added during resolve.
    expect(completion.documentation, isNull);
    expect(completion.textEdit, isNull);

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
        resolved.detail, startsWith("Auto import from '../other_file.dart'"));

    // Ensure the doc comment was added.
    expect(
      resolved.documentation!.valueEquals('This class is in another file.'),
      isTrue,
    );

    // Ensure the edit was added on.
    expect(resolved.textEdit, isNotNull);

    // There should be no command for this item because it doesn't need imports
    // in other files. Same-file completions are in additionalEdits.
    expect(resolved.command, isNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../other_file.dart';

void f() {
  InOtherFile
}
    '''));
  }

  Future<void>
      test_unimportedSymbols_doesNotDuplicate_importedViaMultipleLibraries() async {
    // An item that's already imported through multiple libraries that
    // export it should not result in multiple entries.
    newFile2(
      join(projectFolderPath, 'lib/source_file.dart'),
      '''
      class MyExportedClass {}
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib/reexport1.dart'),
      '''
      export 'source_file.dart';
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib/reexport2.dart'),
      '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import 'reexport1.dart';
import 'reexport2.dart';

void f() {
  MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;

    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
  }

  Future<void>
      test_unimportedSymbols_doesNotDuplicate_importedViaSingleLibrary() async {
    // An item that's already imported through a library that exports it
    // should not result in multiple entries.
    newFile2(
      join(projectFolderPath, 'lib/source_file.dart'),
      '''
      class MyExportedClass {}
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib/reexport1.dart'),
      '''
      export 'source_file.dart';
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib/reexport2.dart'),
      '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import 'reexport1.dart';

void f() {
  MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;

    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
  }

  Future<void> test_unimportedSymbols_doesNotFilterSymbolsWithSameName() async {
    // Classes here are not re-exports, so should not be filtered out.
    newFile2(
      join(projectFolderPath, 'source_file1.dart'),
      'class MyDuplicatedClass {}',
    );
    newFile2(
      join(projectFolderPath, 'source_file2.dart'),
      'class MyDuplicatedClass {}',
    );
    newFile2(
      join(projectFolderPath, 'source_file3.dart'),
      'class MyDuplicatedClass {}',
    );

    final content = '''
void f() {
  MyDuplicated^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions =
        res.where((c) => c.label == 'MyDuplicatedClass').toList();
    expect(completions, hasLength(3));

    // Resolve the completions so we can get the auto-import text.
    final resolvedCompletions =
        await Future.wait(completions.map(resolveCompletion));

    expectAutoImportCompletion(resolvedCompletions, '../source_file1.dart');
    expectAutoImportCompletion(resolvedCompletions, '../source_file2.dart');
    expectAutoImportCompletion(resolvedCompletions, '../source_file3.dart');
  }

  Future<void> test_unimportedSymbols_enumValues() async {
    newFile2(
      join(projectFolderPath, 'source_file.dart'),
      '''
      enum MyExportedEnum { One, Two }
      ''',
    );

    final content = '''
void f() {
  var a = MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final enumCompletions =
        res.where((c) => c.label.startsWith('MyExportedEnum')).toList();
    expect(
        enumCompletions.map((c) => c.label),
        unorderedEquals(
            ['MyExportedEnum', 'MyExportedEnum.One', 'MyExportedEnum.Two']));

    final completion =
        enumCompletions.singleWhere((c) => c.label == 'MyExportedEnum.One');

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
        resolved.detail, startsWith("Auto import from '../source_file.dart'"));

    // Ensure the edit was added on.
    expect(resolved.textEdit, isNotNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../source_file.dart';

void f() {
  var a = MyExportedEnum.One
}
    '''));
  }

  Future<void> test_unimportedSymbols_enumValuesAlreadyImported() async {
    newFile2(
      join(projectFolderPath, 'lib', 'source_file.dart'),
      '''
      enum MyExportedEnum { One, Two }
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib', 'reexport1.dart'),
      '''
      export 'source_file.dart';
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib', 'reexport2.dart'),
      '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import 'reexport1.dart';

void f() {
  var a = MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions =
        res.where((c) => c.label == 'MyExportedEnum.One').toList();
    expect(completions, hasLength(1));
    final resolved = await resolveCompletion(completions.first);
    // It should not include auto-import text since it's already imported.
    expect(resolved.detail, isNot(contains('Auto import from')));
  }

  Future<void> test_unimportedSymbols_filtersOutAlreadyImportedSymbols() async {
    newFile2(
      join(projectFolderPath, 'lib', 'source_file.dart'),
      '''
      class MyExportedClass {}
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib', 'reexport1.dart'),
      '''
      export 'source_file.dart';
      ''',
    );
    newFile2(
      join(projectFolderPath, 'lib', 'reexport2.dart'),
      '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import 'reexport1.dart';

void f() {
  MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(1));
    final resolved = await resolveCompletion(completions.first);
    // It should not include auto-import text since it's already imported.
    expect(resolved.detail, isNull);
  }

  Future<void> test_unimportedSymbols_importsPackageUri() async {
    newFile2(
      join(projectFolderPath, 'lib', 'my_class.dart'),
      'class MyClass {}',
    );

    final content = '''
void f() {
  MyClas^
}
    ''';

    final expectedContent = '''
import 'package:test/my_class.dart';

void f() {
  MyClass
}
    ''';

    final completionLabel = 'MyClass';

    await _checkCompletionEdits(
      mainFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void>
      test_unimportedSymbols_includesReexportedSymbolsForEachFile() async {
    newFile2(
      join(projectFolderPath, 'source_file.dart'),
      '''
      class MyExportedClass {}
      ''',
    );
    newFile2(
      join(projectFolderPath, 'reexport1.dart'),
      '''
      export 'source_file.dart';
      ''',
    );
    newFile2(
      join(projectFolderPath, 'reexport2.dart'),
      '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
void f() {
  MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions = res.where((c) => c.label == 'MyExportedClass').toList();
    expect(completions, hasLength(3));

    // Resolve the completions so we can get the auto-import text.
    final resolvedCompletions =
        await Future.wait(completions.map(resolveCompletion));

    expectAutoImportCompletion(resolvedCompletions, '../source_file.dart');
    expectAutoImportCompletion(resolvedCompletions, '../reexport1.dart');
    expectAutoImportCompletion(resolvedCompletions, '../reexport2.dart');
  }

  Future<void> test_unimportedSymbols_insertReplaceRanges() async {
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      '''
      /// This class is in another file.
      class InOtherFile {}
      ''',
    );

    final content = '''
void f() {
  InOtherF^il
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
      textDocumentCapabilities: withCompletionItemInsertReplaceSupport(
          emptyTextDocumentClientCapabilities),
      workspaceCapabilities:
          withApplyEditSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Find the completion for the class in the other file.
    final completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);

    // Expect no docs or text edit, since these are added during resolve.
    expect(completion.documentation, isNull);
    expect(completion.textEdit, isNull);

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
        resolved.detail, startsWith("Auto import from '../other_file.dart'"));

    // Ensure the doc comment was added.
    expect(
      resolved.documentation!.valueEquals('This class is in another file.'),
      isTrue,
    );

    // Ensure the edit was added on.
    expect(resolved.textEdit, isNotNull);

    // There should be no command for this item because it doesn't need imports
    // in other files. Same-file completions are in additionalEdits.
    expect(resolved.command, isNull);

    // Apply both the main completion edit and the additionalTextEdits atomically
    // then check the contents.

    final newContentReplaceMode = applyTextEdits(
      withoutMarkers(content),
      [textEditForReplace(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );
    final newContentInsertMode = applyTextEdits(
      withoutMarkers(content),
      [textEditForInsert(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContentReplaceMode, equals('''
import '../other_file.dart';

void f() {
  InOtherFile
}
    '''));
    // In insert mode, we'd have the trailing "il" still after the caret.
    expect(newContentInsertMode, equals('''
import '../other_file.dart';

void f() {
  InOtherFileil
}
    '''));
  }

  Future<void> test_unimportedSymbols_insertsIntoPartFiles() async {
    // File we'll be adding an import for.
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      'class InOtherFile {}',
    );

    // File that will have the import added.
    final parentContent = '''part 'main.dart';''';
    final parentFilePath = newFile2(
      join(projectFolderPath, 'lib', 'parent.dart'),
      parentContent,
    ).path;

    // File that we're invoking completion in.
    final content = '''
part of 'parent.dart';
void f() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completion = res.singleWhere((c) => c.label == 'InOtherFile');
    expect(completion, isNotNull);

    // Resolve the completion item to get its edits.
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);
    // Ensure it has a command, since it will need to make edits in other files
    // and that's done by telling the server to send a workspace/applyEdit. LSP
    // doesn't currently support these other-file edits in the completion.
    // See https://github.com/microsoft/language-server-protocol/issues/749
    expect(resolved.command, isNotNull);

    // Apply all current-document edits.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );
    expect(newContent, equals('''
part of 'parent.dart';
void f() {
  InOtherFile
}
    '''));

    // Execute the associated command (which will handle edits in other files).
    ApplyWorkspaceEditParams? editParams;
    final commandResponse = await handleExpectedRequest<Object?,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(resolved.command!),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return ApplyWorkspaceEditResponse(applied: true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back.
    expect(editParams, isNotNull);
    expect(editParams!.edit.changes, isNotNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      parentFilePath: withoutMarkers(parentContent),
    };
    applyChanges(contents, editParams!.edit.changes!);

    // Check the parent file was modified to include the import by the edits
    // that came from the server.
    expect(contents[parentFilePath], equals('''
import '../other_file.dart';

part 'main.dart';'''));
  }

  Future<void> test_unimportedSymbols_members() async {
    newFile2(
      join(projectFolderPath, 'source_file.dart'),
      '''
      class MyExportedClass {
        DateTime myInstanceDateTime;
        static DateTime myStaticDateTimeField;
        static DateTime get myStaticDateTimeGetter => null;
      }
      ''',
    );

    final content = '''
void f() {
  var a = MyExported^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completions =
        res.where((c) => c.label.startsWith('MyExportedClass')).toList();
    expect(
        completions.map((c) => c.label),
        unorderedEquals([
          'MyExportedClass',
          'MyExportedClass()',
          // The instance field should not show up.
          'MyExportedClass.myStaticDateTimeField',
          'MyExportedClass.myStaticDateTimeGetter'
        ]));

    final completion = completions
        .singleWhere((c) => c.label == 'MyExportedClass.myStaticDateTimeField');

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Ensure the detail field was update to show this will auto-import.
    expect(
        resolved.detail, startsWith("Auto import from '../source_file.dart'"));

    // Ensure the edit was added on.
    expect(resolved.textEdit, isNotNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../source_file.dart';

void f() {
  var a = MyExportedClass.myStaticDateTimeField
}
    '''));
  }

  /// This test reproduces a bug where the pathKey hash used in
  /// available_declarations.dart would not change with the contents of the file
  /// (as it always used 0 as the modification stamp) which would prevent
  /// completion including items from files that were open (had overlays).
  /// https://github.com/Dart-Code/Dart-Code/issues/2286#issuecomment-658597532
  Future<void> test_unimportedSymbols_modifiedFiles() async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other_file.dart');
    final otherFileUri = Uri.file(otherFilePath);

    final mainFileContent = 'MyOtherClass^';
    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(mainFileContent));
    await initialAnalysis;

    // Start with a blank file.
    newFile2(otherFilePath, '');
    await openFile(otherFileUri, '');
    await pumpEventQueue(times: 5000);

    // Reopen the file with a class definition.
    await closeFile(otherFileUri);
    await openFile(otherFileUri, 'class MyOtherClass {}');
    await pumpEventQueue(times: 5000);

    // Ensure the class appears in completion.
    final completions =
        await getCompletion(mainFileUri, positionFromMarker(mainFileContent));
    final matching =
        completions.where((c) => c.label == 'MyOtherClass').toList();
    expect(matching, hasLength(1));
  }

  Future<void> test_unimportedSymbols_namedConstructors() async {
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      '''
      /// This class is in another file.
      class InOtherFile {
        InOtherFile.fromJson() {}
      }
      ''',
    );

    final content = '''
void f() {
  var a = InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Find the completion for the class in the other file.
    final completion =
        res.singleWhere((c) => c.label == 'InOtherFile.fromJson()');
    expect(completion, isNotNull);

    // Expect no docs or text edit, since these are added during resolve.
    expect(completion.documentation, isNull);
    expect(completion.textEdit, isNull);

    // Resolve the completion item (via server) to get its edits. This is the
    // LSP's equiv of getSuggestionDetails() and is invoked by LSP clients to
    // populate additional info (in our case, the additional edits for inserting
    // the import).
    final resolved = await resolveCompletion(completion);
    expect(resolved, isNotNull);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolved.textEdit!)]
          .followedBy(resolved.additionalTextEdits!)
          .toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../other_file.dart';

void f() {
  var a = InOtherFile.fromJson
}
    '''));
  }

  Future<void>
      test_unimportedSymbols_preferRelativeImportsLib_insideLib() async {
    _enableLints([LintNames.prefer_relative_imports]);
    final importingFilePath =
        join(projectFolderPath, 'lib', 'nested1', 'main.dart');
    final importingFileUri = Uri.file(importingFilePath);
    final importedFilePath =
        join(projectFolderPath, 'lib', 'nested2', 'imported.dart');

    // Create a file that will be auto-imported from completion.
    newFile2(importedFilePath, 'class MyClass {}');

    final content = '''
void f() {
  MyClas^
}
    ''';

    final expectedContent = '''
import '../nested2/imported.dart';

void f() {
  MyClass
}
    ''';

    final completionLabel = 'MyClass';

    await _checkCompletionEdits(
      importingFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void>
      test_unimportedSymbols_preferRelativeImportsLib_outsideLib() async {
    // Files outside of the lib folder should still get absolute imports to
    // files inside lib, even with the lint enabled.
    _enableLints([LintNames.prefer_relative_imports]);
    final importingFilePath =
        join(projectFolderPath, 'bin', 'nested1', 'main.dart');
    final importingFileUri = Uri.file(importingFilePath);
    final importedFilePath =
        join(projectFolderPath, 'lib', 'nested2', 'imported.dart');

    // Create a file that will be auto-imported from completion.
    newFile2(importedFilePath, 'class MyClass {}');

    final content = '''
void f() {
  MyClas^
}
    ''';

    final expectedContent = '''
import 'package:test/nested2/imported.dart';

void f() {
  MyClass
}
    ''';

    final completionLabel = 'MyClass';

    await _checkCompletionEdits(
      importingFileUri,
      content,
      completionLabel,
      expectedContent,
    );
  }

  Future<void> test_unimportedSymbols_unavailableIfDisabled() async {
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      'class InOtherFile {}',
    );

    final content = '''
void f() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    // Support applyEdit, but explicitly disable the suggestions.
    await initialize(
      initializationOptions: {
        'suggestFromUnimportedLibraries': false,
      },
      workspaceCapabilities:
          withApplyEditSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Ensure the item doesn't appear in the results (because we might not
    // be able to execute the import edits if they're in another file).
    final completion = res.singleWhereOrNull((c) => c.label == 'InOtherFile');
    expect(completion, isNull);
  }

  Future<void> test_unimportedSymbols_unavailableWithoutApplyEdit() async {
    // If client doesn't advertise support for workspace/applyEdit, we won't
    // include suggestion sets.
    newFile2(
      join(projectFolderPath, 'other_file.dart'),
      'class InOtherFile {}',
    );

    final content = '''
void f() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Ensure the item doesn't appear in the results (because we might not
    // be able to execute the import edits if they're in another file).
    final completion = res.singleWhereOrNull((c) => c.label == 'InOtherFile');
    expect(completion, isNull);
  }

  Future<void> test_unopenFile() async {
    final content = '''
    class MyClass {
      String abcdefghij;
    }

    void f() {
      MyClass a;
      a.abc^
    }
    ''';

    newFile2(mainFilePath, withoutMarkers(content));
    await initialize();
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.insertTextFormat,
        anyOf(equals(InsertTextFormat.PlainText), isNull));
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    final updated = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(item.textEdit!)],
    );
    expect(updated, contains('a.abcdefghij'));
  }

  /// Sets up the server with a file containing [content] and checks that
  /// accepting a specific completion produces [expectedContent].
  ///
  /// [content] should contain a `^` at the location where completion should be
  /// invoked/accepted.
  Future<void> _checkCompletionEdits(
    Uri fileUri,
    String content,
    String completionLabel,
    String expectedContent,
  ) async {
    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
        workspaceCapabilities:
            withApplyEditSupport(emptyWorkspaceClientCapabilities));
    await openFile(fileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(fileUri, positionFromMarker(content));

    final completion = res.where((c) => c.label == completionLabel).single;
    final resolvedCompletion = await resolveCompletion(completion);

    // Apply both the main completion edit and the additionalTextEdits atomically.
    final newContent = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(resolvedCompletion.textEdit!)]
          .followedBy(resolvedCompletion.additionalTextEdits!)
          .toList(),
    );

    expect(newContent, equals(expectedContent));
  }

  Future<void> _checkResultsForTriggerCharacters(String content,
      List<String> triggerCharacters, Matcher expectedResults) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    for (final triggerCharacter in triggerCharacters) {
      final context = CompletionContext(
          triggerKind: CompletionTriggerKind.TriggerCharacter,
          triggerCharacter: triggerCharacter);
      final res = await getCompletion(mainFileUri, positionFromMarker(content),
          context: context);
      expect(res, expectedResults);
    }
  }

  void _enableLints(List<String> lintNames) {
    registerLintRules();
    final lintsYaml = lintNames.map((name) => '    - $name\n').join();
    newFile2(analysisOptionsPath, '''
linter:
  rules:
$lintsYaml
''');
  }
}

@reflectiveTest
class CompletionTestWithNullSafetyTest extends AbstractLspAnalysisServerTest {
  @override
  String get testPackageLanguageVersion => latestLanguageVersion;

  Future<void> test_completeFunctionCalls_requiredNamed() async {
    final content = '''
    void myFunction(String a, int b, {required String c, String d = ''}) {}

    void f() {
      [[myFu^]]
    }
    ''';

    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'completeFunctionCalls': true},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'myFunction(…)');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, equals(r'myFunction(${1:a}, ${2:b}, c: ${3:c})'));
    final textEdit = toTextEdit(item.textEdit!);
    expect(textEdit.newText, equals(item.insertText));
    expect(textEdit.range, equals(rangeFromMarkers(content)));
  }

  Future<void> test_completeFunctionCalls_requiredNamed_suggestionSet() async {
    final otherFile = join(projectFolderPath, 'lib', 'other.dart');
    newFile2(
      otherFile,
      "void myFunction(String a, int b, {required String c, String d = ''}) {}",
    );
    final content = '''
    void f() {
      [[myFu^]]
    }
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities: withApplyEditSupport(
            withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      ),
      {'completeFunctionCalls': true},
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;

    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'myFunction(…)');
    // Ensure the snippet comes through in the expected format with the expected
    // placeholders.
    expect(item.insertTextFormat, equals(InsertTextFormat.Snippet));
    expect(item.insertText, equals(r'myFunction(${1:a}, ${2:b}, c: ${3:c})'));
    expect(item.textEdit, isNull);

    // Ensure the item can be resolved and gets a proper TextEdit.
    final resolved = await resolveCompletion(item);
    expect(resolved.textEdit, isNotNull);
    final textEdit = toTextEdit(resolved.textEdit!);
    expect(textEdit.newText, equals(item.insertText));
    expect(textEdit.range, equals(rangeFromMarkers(content)));
  }

  Future<void> test_nullableTypes() async {
    final content = '''
    String? foo(int? a, [int b = 1]) {}

    void f() {
      fo^
    }
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    final completion = res.singleWhere((c) => c.label.startsWith('foo'));
    expect(completion.detail, '(int? a, [int b = 1]) → String?');
  }
}

@reflectiveTest
class DartSnippetCompletionTest extends SnippetCompletionTest {
  Future<void> test_snippets_class() async {
    final content = '''
clas^
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartClassSnippetProducer.prefix,
      label: DartClassSnippetProducer.label,
    );

    expect(updated, r'''
class ${1:ClassName} {
  $0
}
''');
  }

  /// Checks that the `enableSnippets` setting can disable snippets even if the
  /// client supports them.
  Future<void> test_snippets_disabled() async {
    final content = '^';

    // Advertise support (this is done by the editor), but with the user
    // preference disabled.
    await provideConfig(
      () => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
        workspaceCapabilities:
            withConfigurationSupport(emptyWorkspaceClientCapabilities),
      ),
      {'enableSnippets': false},
    );

    await expectNoSnippets(content);
  }

  Future<void> test_snippets_doWhile() async {
    final content = '''
void f() {
  do^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartDoWhileLoopSnippetProducer.prefix,
      label: DartDoWhileLoopSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  do {
    $0
  } while (${1:condition});
}
''');
  }

  Future<void>
      test_snippets_flutterStateless_notAvailable_notFlutterProject() async {
    final content = '''
class A {}

stle^

class B {}
''';

    await initializeWithSnippetSupport();
    await expectNoSnippet(
      content,
      FlutterStatelessWidgetSnippetProducer.prefix,
    );
  }

  Future<void> test_snippets_for() async {
    final content = '''
void f() {
  for^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartForLoopSnippetProducer.prefix,
      label: DartForLoopSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  for (var i = 0; i < ${1:count}; i++) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_forIn() async {
    final content = '''
void f() {
  forin^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartForInLoopSnippetProducer.prefix,
      label: DartForInLoopSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  for (var ${1:element} in ${2:collection}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_if() async {
    final content = '''
void f() {
  if^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartIfSnippetProducer.prefix,
      label: DartIfSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  if (${1:condition}) {
    $0
  }
}
''');
  }

  Future<void> test_snippets_ifElse() async {
    final content = '''
void f() {
  if^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartIfElseSnippetProducer.prefix,
      label: DartIfElseSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  if (${1:condition}) {
    $0
  } else {
    
  }
}
''');
  }

  Future<void> test_snippets_mainFunction() async {
    final content = '''
class A {}

main^

class B {}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartMainFunctionSnippetProducer.prefix,
      label: DartMainFunctionSnippetProducer.label,
    );

    expect(updated, r'''
class A {}

void main(List<String> args) {
  $0
}

class B {}
''');
  }

  Future<void> test_snippets_notSupported() async {
    final content = '^';

    // If we don't send support for Snippet CompletionItem kinds, we don't
    // expect any snippets at all.
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.kind == CompletionItemKind.Snippet), isFalse);
  }

  Future<void> test_snippets_switch() async {
    final content = '''
void f() {
  swi^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartSwitchSnippetProducer.prefix,
      label: DartSwitchSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  switch (${1:expression}) {
    case ${2:value}:
      $0
      break;
    default:
  }
}
''');
  }

  Future<void> test_snippets_testBlock() async {
    mainFilePath = join(projectFolderPath, 'test', 'foo_test.dart');
    mainFileUri = Uri.file(mainFilePath);
    final content = '''
void f() {
  test^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartTestBlockSnippetProducer.prefix,
      label: DartTestBlockSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  test('${1:test name}', () {
    $0
  });
}
''');
  }

  Future<void> test_snippets_testGroupBlock() async {
    mainFilePath = join(projectFolderPath, 'test', 'foo_test.dart');
    mainFileUri = Uri.file(mainFilePath);
    final content = '''
void f() {
  group^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartTestGroupBlockSnippetProducer.prefix,
      label: DartTestGroupBlockSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  group('${1:group name}', () {
    $0
  });
}
''');
  }

  Future<void> test_snippets_tryCatch() async {
    final content = '''
void f() {
  tr^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartTryCatchSnippetProducer.prefix,
      label: DartTryCatchSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  try {
    $0
  } catch (${1:e}) {
    
  }
}
''');
  }

  Future<void> test_snippets_while() async {
    final content = '''
void f() {
  while^
}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: DartWhileLoopSnippetProducer.prefix,
      label: DartWhileLoopSnippetProducer.label,
    );

    expect(updated, r'''
void f() {
  while (${1:condition}) {
    $0
  }
}
''');
  }
}

@reflectiveTest
class FlutterSnippetCompletionTest extends SnippetCompletionTest {
  /// Standard import statements expected for basic Widgets.
  String get expectedImports => '''
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';''';

  /// Nullability suffix expected in this test class.
  ///
  /// Used to allow all tests to be run in both modes without having to
  /// duplicate all tests ([FlutterSnippetCompletionWithLatestLanguageVersionTest]
  /// overrides this).
  String get expectedNullableSuffix => '';

  /// Constructor params expected on Widget classes.
  String get expectedWidgetConstructorParams => '({Key key}) : super(key: key)';

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      projectFolderPath,
      flutter: true,
    );
  }

  Future<void> test_snippets_flutterStateful() async {
    final content = '''
import 'package:flutter/widgets.dart';

class A {}

stful^

class B {}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatefulWidgetSnippetProducer.prefix,
      label: FlutterStatefulWidgetSnippetProducer.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatefulWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  State<\${1:MyWidget}> createState() => _\${1:MyWidget}State();
}

class _\${1:MyWidget}State extends State<\${1:MyWidget}> {
  @override
  Widget build(BuildContext context) {
    \$0
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStatefulWithAnimationController() async {
    final content = '''
import 'package:flutter/widgets.dart';

class A {}

stanim^

class B {}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix:
          FlutterStatefulWidgetWithAnimationControllerSnippetProducer.prefix,
      label: FlutterStatefulWidgetWithAnimationControllerSnippetProducer.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatefulWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  State<\${1:MyWidget}> createState() => _\${1:MyWidget}State();
}

class _\${1:MyWidget}State extends State<\${1:MyWidget}>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    \$0
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless() async {
    final content = '''
import 'package:flutter/widgets.dart';

class A {}

stle^

class B {}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidgetSnippetProducer.prefix,
      label: FlutterStatelessWidgetSnippetProducer.label,
    );

    expect(updated, '''
import 'package:flutter/widgets.dart';

class A {}

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    \$0
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports() async {
    final content = '''
class A {}

stle^

class B {}
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidgetSnippetProducer.prefix,
      label: FlutterStatelessWidgetSnippetProducer.label,
    );

    expect(updated, '''
$expectedImports

class A {}

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    \$0
  }
}

class B {}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports_onlyPrefix() async {
    final content = '''
stless^
''';

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidgetSnippetProducer.prefix,
      label: FlutterStatelessWidgetSnippetProducer.label,
    );

    expect(updated, '''
$expectedImports

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    \$0
  }
}
''');
  }

  Future<void> test_snippets_flutterStateless_addsImports_zeroOffset() async {
    final content = '''
^
'''; // Deliberate trailing newline to ensure imports aren't inserted at "end".

    await initializeWithSnippetSupport();
    final updated = await expectAndApplySnippet(
      content,
      prefix: FlutterStatelessWidgetSnippetProducer.prefix,
      label: FlutterStatelessWidgetSnippetProducer.label,
    );

    expect(updated, '''
$expectedImports

class \${1:MyWidget} extends StatelessWidget {
  const \${1:MyWidget}$expectedWidgetConstructorParams;

  @override
  Widget build(BuildContext context) {
    \$0
  }
}
''');
  }

  Future<void> test_snippets_flutterStateless_notAvailable_notTopLevel() async {
    final content = '''
class A {

  stle^

}
''';

    await initializeWithSnippetSupport();
    await expectNoSnippet(
      content,
      FlutterStatelessWidgetSnippetProducer.prefix,
    );
  }

  Future<void> test_snippets_flutterStateless_outsideAnalysisRoot() async {
    final content = '''
stle^
''';

    await initializeWithSnippetSupport();
    final otherFileUri = Uri.file(convertPath('/other/file.dart'));
    await openFile(otherFileUri, withoutMarkers(content));
    final res = await getCompletion(otherFileUri, positionFromMarker(content));
    final snippetItems = res.where((c) => c.kind == CompletionItemKind.Snippet);
    expect(snippetItems, hasLength(0));
  }
}

@reflectiveTest
class FlutterSnippetCompletionWithLatestLanguageVersionTest
    extends FlutterSnippetCompletionTest {
  @override
  String get expectedImports => '''
import 'package:flutter/src/widgets/framework.dart';''';

  @override
  String get expectedNullableSuffix => '?';

  @override
  String get expectedWidgetConstructorParams => '({super.key})';

  @override
  String get testPackageLanguageVersion => latestLanguageVersion;
}

abstract class SnippetCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  /// Expect that there is a snippet for [prefix] at [position] with the label
  /// [label] and return the results of applying it to [content].
  Future<String> expectAndApplySnippet(
    String content, {
    required String prefix,
    required String label,
  }) async {
    final snippet = await expectSnippet(
      content,
      prefix: prefix,
      label: label,
    );

    // Also apply the edit and check that it went in the right place with the
    // correct formatting. Edit groups will just appear in the raw textmate
    // snippet syntax here, as we don't do any special handling of them (and
    // assume what's coded here is correct, and that the client will correctly
    // interpret them).
    final updated = applyTextEdits(
      withoutMarkers(content),
      [toTextEdit(snippet.textEdit!)]
          .followedBy(snippet.additionalTextEdits!)
          .toList(),
    );
    return updated;
  }

  /// Expect that there is no snippet for [prefix] at the position of `^` within
  /// [content].
  Future<void> expectNoSnippet(
    String content,
    String prefix,
  ) async {
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final hasSnippet = res.any((c) => c.filterText == prefix);
    expect(hasSnippet, isFalse);
  }

  /// Expect that there are no snippets at the position of `^` within [content].
  Future<void> expectNoSnippets(String content) async {
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final hasAnySnippet = res.any((c) => c.kind == CompletionItemKind.Snippet);
    expect(hasAnySnippet, isFalse);
  }

  /// Expect that there is a snippet for [prefix] with the label [label] at
  /// [position] in [content].
  Future<CompletionItem> expectSnippet(
    String content, {
    required String prefix,
    required String label,
  }) async {
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere(
      (c) => c.filterText == prefix && c.label == label,
    );
    expect(item.insertTextFormat, InsertTextFormat.Snippet);
    expect(item.insertText, isNull);
    expect(item.textEdit, isNotNull);
    return item;
  }

  Future<void> initializeWithSnippetSupport() => initialize(
        textDocumentCapabilities: withCompletionItemSnippetSupport(
            emptyTextDocumentClientCapabilities),
      );
}
