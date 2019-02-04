// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HoverTest);
  });
}

@reflectiveTest
class HoverTest extends AbstractLspAnalysisServerTest {
  test_hover_bad_position() async {
    await initialize();
    await openFile(mainFileUri, '');
    await expectLater(
      () => getHover(mainFileUri, new Position(999, 999)),
      throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)),
    );
  }

  test_markdown_isFormattedForDisplay() async {
    final content = '''
    /// This is a string.
    ///
    /// {@template foo}
    /// With some [refs] and some
    /// [links](https://www.dartlang.org/)
    /// {@endTemplate foo}
    ///
    /// ```dart sample
    /// print();
    /// ```
    String [[a^bc]];
    ''';

    final expectedHoverContent = '''
```dart
String abc
```
---
This is a string.

With some [refs] and some
[links](https://www.dartlang.org/)

```dart
print();
```
    '''
        .trim();

    await initialize(
        textDocumentCapabilities: withHoverContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    final markup = _getMarkupContents(hover);
    expect(markup.kind, equals(MarkupKind.Markdown));
    expect(markup.value, equals(expectedHoverContent));
  }

  test_markdown_simple() async {
    final content = '''
    /// This is a string.
    String [[a^bc]];
    ''';

    await initialize(
        textDocumentCapabilities: withHoverContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    final markup = _getMarkupContents(hover);
    expect(markup.kind, equals(MarkupKind.Markdown));
    expect(markup.value, contains('This is a string.'));
  }

  test_noElement() async {
    final content = '''
    String abc;

    ^

    int a;
    ''';

    await initialize(
        textDocumentCapabilities: withHoverContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.Markdown]));
    await openFile(mainFileUri, withoutMarkers(content));
    var hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNull);
  }

  test_plainText_simple() async {
    final content = '''
    /// This is a string.
    String [[a^bc]];
    ''';

    await initialize(
        textDocumentCapabilities: withHoverContentFormat(
            emptyTextDocumentClientCapabilities, [MarkupKind.PlainText]));
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    // Ensure we got PlainText back as the type, even though we're sending the
    // same markdown content.
    final markup = _getMarkupContents(hover);
    expect(markup.kind, equals(MarkupKind.PlainText));
    expect(markup.value, contains('This is a string.'));
  }

  test_string_noDocComment() async {
    final content = '''
    String [[a^bc]];
    ''';

    final expectedHoverContent = '''
```dart
String abc
```
    '''
        .trim();

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    expect(_getStringContents(hover), equals(expectedHoverContent));
  }

  test_string_reflectsLatestEdits() async {
    final original = '''
    /// Original string.
    String [[a^bc]];
    ''';
    final updated = '''
    /// Updated string.
    String [[a^bc]];
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(original));
    var hover = await getHover(mainFileUri, positionFromMarker(original));
    var contents = _getStringContents(hover);
    expect(contents, contains('Original'));

    await replaceFile(222, mainFileUri, withoutMarkers(updated));
    hover = await getHover(mainFileUri, positionFromMarker(updated));
    contents = _getStringContents(hover);
    expect(contents, contains('Updated'));
  }

  test_string_simple() async {
    final content = '''
    /// This is a string.
    String [[a^bc]];
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    final contents = _getStringContents(hover);
    expect(contents, contains('This is a string.'));
  }

  test_unopenFile() async {
    final content = '''
    /// This is a string.
    String [[a^bc]];
    ''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    final markup = _getStringContents(hover);
    expect(markup, contains('This is a string.'));
  }

  MarkupContent _getMarkupContents(Hover hover) {
    return hover.contents.map(
      (t1) => throw 'Hover contents were String, not MarkupContent',
      (t2) => t2,
    );
  }

  String _getStringContents(Hover hover) {
    return hover.contents.map(
      (t1) => t1,
      (t2) => throw 'Hover contents were MarkupContent, not String',
    );
  }
}
