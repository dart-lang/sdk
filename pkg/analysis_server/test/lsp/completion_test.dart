// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTest);
  });
}

@reflectiveTest
class CompletionTest extends AbstractLspAnalysisServerTest {
  test_completionKinds_default() async {
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

  test_completionKinds_imports() async {
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

  test_completionKinds_supportedSubset() async {
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

  test_completionTriggerKinds_invalidParams() async {
    await initialize();

    final invalidTriggerKind = CompletionTriggerKind.fromJson(-1);
    final request = getCompletion(
      mainFileUri,
      new Position(0, 0),
      context: new CompletionContext(invalidTriggerKind, 'A'),
    );

    await expectLater(
        request, throwsA(isResponseError(ErrorCodes.InvalidParams)));
  }

  test_gettersAndSetters() async {
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

  test_insideString() async {
    final content = '''
    var a = "This is ^a test"
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final res = await getCompletion(mainFileUri, positionFromMarker(content));
    expect(res, isEmpty);
  }

  test_isDeprecated_notSupported() async {
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

  test_isDeprecated_supported() async {
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

  test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final res = await getCompletion(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  test_plainText() async {
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
    expect(item.insertTextFormat, equals(InsertTextFormat.PlainText));
    // ignore: deprecated_member_use_from_same_package
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    final updated = applyTextEdits(withoutMarkers(content), [item.textEdit]);
    expect(updated, contains('a.abcdefghij'));
  }

  test_unopenFile() async {
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
    expect(item.insertTextFormat, equals(InsertTextFormat.PlainText));
    // ignore: deprecated_member_use_from_same_package
    expect(item.insertText, anyOf(equals('abcdefghij'), isNull));
    final updated = applyTextEdits(withoutMarkers(content), [item.textEdit]);
    expect(updated, contains('a.abcdefghij'));
  }
}
