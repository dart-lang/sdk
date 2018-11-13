// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HoverTest);
  });
}

@reflectiveTest
class HoverTest extends AbstractLspAnalysisServerTest {
  test_hover_after_document_changes() async {
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
    expect(hover.contents.value, contains('Original'));

    await replaceFile(mainFileUri, withoutMarkers(updated));
    hover = await getHover(mainFileUri, positionFromMarker(updated));
    expect(hover.contents.value, contains('Updated'));
  }

  test_hover_simple() async {
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

This is a string.

With some [refs] and some
[links](https://www.dartlang.org/)

```dart
print();
```
    '''
        .trim();

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNotNull);
    expect(hover.range, equals(rangeFromMarkers(content)));
    expect(hover.contents, isNotNull);
    expect(hover.contents.kind, equals(MarkupKind.Markdown));
    expect(hover.contents.value, equals(expectedHoverContent));
  }

  test_hover_no_doc_comment() async {
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
    expect(hover.contents.kind, equals(MarkupKind.Markdown));
    expect(hover.contents.value, equals(expectedHoverContent));
  }

  test_hover_missing() async {
    final content = '''
    String abc;

    ^

    int a;
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    var hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover, isNull);
  }
}
