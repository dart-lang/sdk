// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTest);
  });
}

@reflectiveTest
class CompletionTest extends AbstractLspAnalysisServerTest {
  void expectAutoImportCompletion(List<CompletionItem> items, String file) {
    expect(
      items.singleWhere(
        (c) => c.detail?.contains("Auto import from '$file'") ?? false,
        orElse: () => null,
      ),
      isNotNull,
    );
  }

  Future<void> test_completionKinds_default() async {
    newFile(join(projectFolderPath, 'file.dart'));
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

    main() {
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

  Future<void> test_completionTriggerKinds_invalidParams() async {
    await initialize();

    final invalidTriggerKind = CompletionTriggerKind.fromJson(-1);
    final request = getCompletion(
      mainFileUri,
      Position(0, 0),
      context: CompletionContext(invalidTriggerKind, 'A'),
    );

    await expectLater(
        request, throwsA(isResponseError(ErrorCodes.InvalidParams)));
  }

  Future<void> test_gettersAndSetters() async {
    final content = '''
    class MyClass {
      String get justGetter => '';
      String set justSetter(String value) {}
      String get getterAndSetter => '';
      String set getterAndSetter(String value) {}
    }

    main() {
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
    [getter, setter, both].forEach((item) {
      expect(item.kind, equals(CompletionItemKind.Property));
    });
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

    main() {
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
    expect(item.detail.toLowerCase(), contains('deprecated'));
  }

  Future<void> test_isDeprecated_supported() async {
    final content = '''
    class MyClass {
      @deprecated
      String abcdefghij;
    }

    main() {
      MyClass a;
      a.abc^
    }
    ''';

    await initialize(
        textDocumentCapabilities: withCompletionItemDeprecatedSupport(
            emptyTextDocumentClientCapabilities));
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.deprecated, isTrue);
    // If the client says it supports the deprecated flag, we should not show
    // deprecated in the details.
    expect(item.detail, isNot(contains('deprecated')));
  }

  Future<void> test_namedArg_plainText() async {
    final content = '''
    class A { const A({int one}); }
    @A(^)
    main() { }
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'one: '), isTrue);
    final item = res.singleWhere((c) => c.label == 'one: ');
    expect(item.insertTextFormat,
        anyOf(equals(InsertTextFormat.PlainText), isNull));
    expect(item.insertText, anyOf(equals('test'), isNull));
    final updated = applyTextEdits(withoutMarkers(content), [item.textEdit]);
    expect(updated, contains('one: '));
  }

  Future<void> test_namedArg_snippetStringSelection() async {
    final content = '''
    class A { const A({int one}); }
    @A(^)
    main() { }
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
    expect(item.insertText, equals(r'one: ${1:}'));
    expect(item.textEdit.newText, equals(r'one: ${1:}'));
    expect(
      item.textEdit.range,
      equals(Range(positionFromMarker(content), positionFromMarker(content))),
    );
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final res = await getCompletion(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_parensNotInFilterTextInsertText() async {
    final content = '''
    class MyClass {}

    main() {
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

    main() {
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
    final updated = applyTextEdits(withoutMarkers(content), [item.textEdit]);
    expect(updated, contains('a.abcdefghij'));
  }

  Future<void> test_suggestionSets() async {
    newFile(
      join(projectFolderPath, 'other_file.dart'),
      content: '''
      /// This class is in another file.
      class InOtherFile {}
      ''',
    );

    final content = '''
main() {
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
      resolved.documentation.valueEquals('This class is in another file.'),
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
      [resolved.textEdit].followedBy(resolved.additionalTextEdits).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../other_file.dart';

main() {
  InOtherFile
}
    '''));
  }

  Future<void> test_suggestionSets_doesNotFilterSymbolsWithSameName() async {
    // Classes here are not re-exports, so should not be filtered out.
    newFile(
      join(projectFolderPath, 'source_file1.dart'),
      content: 'class MyDuplicatedClass {}',
    );
    newFile(
      join(projectFolderPath, 'source_file2.dart'),
      content: 'class MyDuplicatedClass {}',
    );
    newFile(
      join(projectFolderPath, 'source_file3.dart'),
      content: 'class MyDuplicatedClass {}',
    );

    final content = '''
main() {
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

  Future<void> test_suggestionSets_enumValues() async {
    newFile(
      join(projectFolderPath, 'source_file.dart'),
      content: '''
      enum MyExportedEnum { One, Two }
      ''',
    );

    final content = '''
main() {
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
      [resolved.textEdit].followedBy(resolved.additionalTextEdits).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../source_file.dart';

main() {
  var a = MyExportedEnum.One
}
    '''));
  }

  Future<void> test_suggestionSets_enumValuesAlreadyImported() async {
    newFile(
      join(projectFolderPath, 'source_file.dart'),
      content: '''
      enum MyExportedEnum { One, Two }
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport1.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport2.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import '../reexport1.dart';

main() {
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
    expect(resolved.detail, isNull);
  }

  Future<void> test_suggestionSets_filtersOutAlreadyImportedSymbols() async {
    newFile(
      join(projectFolderPath, 'source_file.dart'),
      content: '''
      class MyExportedClass {}
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport1.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport2.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
import '../reexport1.dart';

main() {
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

  Future<void>
      test_suggestionSets_includesReexportedSymbolsForEachFile() async {
    newFile(
      join(projectFolderPath, 'source_file.dart'),
      content: '''
      class MyExportedClass {}
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport1.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );
    newFile(
      join(projectFolderPath, 'reexport2.dart'),
      content: '''
      export 'source_file.dart';
      ''',
    );

    final content = '''
main() {
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

  Future<void> test_suggestionSets_insertsIntoPartFiles() async {
    // File we'll be adding an import for.
    newFile(
      join(projectFolderPath, 'other_file.dart'),
      content: 'class InOtherFile {}',
    );

    // File that will have the import added.
    final parentContent = '''part 'main.dart';''';
    final parentFilePath = newFile(
      join(projectFolderPath, 'lib', 'parent.dart'),
      content: parentContent,
    ).path;

    // File that we're invoking completion in.
    final content = '''
part of 'parent.dart';
main() {
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
      [resolved.textEdit].followedBy(resolved.additionalTextEdits).toList(),
    );
    expect(newContent, equals('''
part of 'parent.dart';
main() {
  InOtherFile
}
    '''));

    // Execute the associated command (which will handle edits in other files).
    ApplyWorkspaceEditParams editParams;
    final commandResponse = await handleExpectedRequest<Object,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResponse>(
      Method.workspace_applyEdit,
      () => executeCommand(resolved.command),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return ApplyWorkspaceEditResponse(true, null);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back.
    expect(editParams, isNotNull);
    expect(editParams.edit.changes, isNotNull);

    // Ensure applying the changes will give us the expected content.
    final contents = {
      parentFilePath: withoutMarkers(parentContent),
    };
    applyChanges(contents, editParams.edit.changes);

    // Check the parent file was modified to include the import by the edits
    // that came from the server.
    expect(contents[parentFilePath], equals('''
import '../other_file.dart';

part 'main.dart';'''));
  }

  Future<void> test_suggestionSets_namedConstructors() async {
    newFile(
      join(projectFolderPath, 'other_file.dart'),
      content: '''
      /// This class is in another file.
      class InOtherFile {
        InOtherFile.fromJson() {}
      }
      ''',
    );

    final content = '''
main() {
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
      [resolved.textEdit].followedBy(resolved.additionalTextEdits).toList(),
    );

    // Ensure both edits were made - the completion, and the inserted import.
    expect(newContent, equals('''
import '../other_file.dart';

main() {
  var a = InOtherFile.fromJson
}
    '''));
  }

  Future<void> test_suggestionSets_unavailableIfDisabled() async {
    newFile(
      join(projectFolderPath, 'other_file.dart'),
      content: 'class InOtherFile {}',
    );

    final content = '''
main() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    // Support applyEdit, but explicitly disable the suggestions.
    await initialize(
      initializationOptions: {'suggestFromUnimportedLibraries': false},
      workspaceCapabilities:
          withApplyEditSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;
    final res = await getCompletion(mainFileUri, positionFromMarker(content));

    // Ensure the item doesn't appear in the results (because we might not
    // be able to execute the import edits if they're in another file).
    final completion = res.singleWhere(
      (c) => c.label == 'InOtherFile',
      orElse: () => null,
    );
    expect(completion, isNull);
  }

  Future<void> test_suggestionSets_unavailableWithoutApplyEdit() async {
    // If client doesn't advertise support for workspace/applyEdit, we won't
    // include suggestion sets.
    newFile(
      join(projectFolderPath, 'other_file.dart'),
      content: 'class InOtherFile {}',
    );

    final content = '''
main() {
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
    final completion = res.singleWhere(
      (c) => c.label == 'InOtherFile',
      orElse: () => null,
    );
    expect(completion, isNull);
  }

  Future<void> test_unopenFile() async {
    final content = '''
    class MyClass {
      String abcdefghij;
    }

    main() {
      MyClass a;
      a.abc^
    }
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res.any((c) => c.label == 'abcdefghij'), isTrue);
    final item = res.singleWhere((c) => c.label == 'abcdefghij');
    expect(item.insertTextFormat,
        anyOf(equals(InsertTextFormat.PlainText), isNull));
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    final updated = applyTextEdits(withoutMarkers(content), [item.textEdit]);
    expect(updated, contains('a.abcdefghij'));
  }
}
