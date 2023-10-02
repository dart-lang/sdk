// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HoverTest);
  });
}

@reflectiveTest
class HoverTest extends AbstractLspAnalysisServerTest {
  @override
  AnalysisServerOptions get serverOptions => AnalysisServerOptions()
    ..enabledExperiments = [
      EnableString.inline_class,
      EnableString.macros,
    ];

  /// Checks whether the correct types of documentation are returned in a Hover
  /// based on [preference].
  Future<void> assertDocumentation(
    String? preference, {
    required bool includesSummary,
    required bool includesFull,
  }) async {
    final code = TestCode.parse('''
    /// Summary.
    ///
    /// Full.
    class ^A {}
    ''');

    final initialAnalysis = waitForAnalysisComplete();
    await provideConfig(
      initialize,
      {
        if (preference != null) 'documentation': preference,
      },
    );
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    final hover = await getHover(mainFileUri, code.position.position);
    final hoverContents = _getStringContents(hover!);

    if (includesSummary) {
      expect(hoverContents, contains('Summary.'));
    } else {
      expect(hoverContents, isNot(contains('Summary.')));
    }

    if (includesFull) {
      expect(hoverContents, contains('Full.'));
    } else {
      expect(hoverContents, isNot(contains('Full.')));
    }
  }

  Future<void> assertMarkdownContents(String content, Matcher matcher) async {
    setHoverContentFormat([MarkupKind.Markdown]);

    final code = TestCode.parse(content);

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    final hover = await getHover(mainFileUri, code.position.position);
    expect(hover, isNotNull);
    expect(hover!.range, equals(code.range.range));
    expect(hover.contents, isNotNull);
    final markup = _getMarkupContents(hover);
    expect(markup.kind, equals(MarkupKind.Markdown));
    expect(markup.value, matcher);
  }

  Future<void> assertPlainTextContents(String content, Matcher matcher) async {
    setHoverContentFormat([MarkupKind.PlainText]);
    final code = TestCode.parse(content);

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;
    final hover = await getHover(mainFileUri, code.position.position);
    expect(hover, isNotNull);
    expect(hover!.range, equals(code.range.range));
    expect(hover.contents, isNotNull);
    final markup = _getMarkupContents(hover);
    expect(markup.kind, equals(MarkupKind.PlainText));
    expect(markup.value, matcher);
  }

  Future<void> assertStringContents(
    String content,
    Matcher matcher, {
    bool waitForAnalysis = false,
    bool withOpenFile = true,
  }) async {
    final code = TestCode.parse(content);

    final initialAnalysis = waitForAnalysis ? waitForAnalysisComplete() : null;
    await initialize();
    if (withOpenFile) {
      await openFile(mainFileUri, code.code);
    } else {
      newFile(mainFilePath, code.code);
    }
    await initialAnalysis;
    final hover = await getHover(mainFileUri, code.position.position);
    expect(hover, isNotNull);
    expect(hover!.range, equals(code.range.range));
    expect(hover.contents, isNotNull);
    final contents = _getStringContents(hover);
    expect(contents, matcher);
  }

  Future<void> test_dartDoc_macros() => assertStringContents(
        waitForAnalysis: true,
        '''
    /// {@template template_name}
    /// This is shared content.
    /// {@endtemplate}
    const String foo = null;

    /// {@macro template_name}
    const String [!f^oo2!] = null;
    ''',
        endsWith('This is shared content.'),
      );

  Future<void> test_dartDocPreference_full() =>
      assertDocumentation('full', includesSummary: true, includesFull: true);

  Future<void> test_dartDocPreference_none() =>
      assertDocumentation('none', includesSummary: false, includesFull: false);

  Future<void> test_dartDocPreference_summary() =>
      assertDocumentation('summary',
          includesSummary: true, includesFull: false);

  /// No preference should result in full docs.
  Future<void> test_dartDocPreference_unset() =>
      assertDocumentation(null, includesSummary: true, includesFull: true);

  Future<void> test_forLoop_declaredVariable() async {
    final content = '''
void f() {
  for (var [!ii^i!] in <String>[]) {}
}
''';
    final expected = '''
```dart
String iii
```
Type: `String`''';
    await assertStringContents(content, equals(expected));
  }

  Future<void> test_forLoop_variableReference() async {
    final content = '''
void f() {
  for (var iii in <String>[]) {
    print([!ii^i!]);
  }
}
''';
    final expected = '''
```dart
String iii
```
Type: `String`''';
    await assertStringContents(content, equals(expected));
  }

  Future<void> test_function_startOfParameterList() => assertStringContents(
        '''
    /// This is a function.
    String [!abc!]^() {}
    ''',
        contains('This is a function.'),
      );

  Future<void> test_function_startOfTypeParameterList() => assertStringContents(
        '''
    /// This is a function.
    String [!abc!]^<T>(T a) {}
    ''',
        contains('This is a function.'),
      );

  Future<void> test_hover_bad_position() async {
    await initialize();
    await openFile(mainFileUri, '');
    await expectLater(
      () => getHover(mainFileUri, Position(line: 999, character: 999)),
      throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)),
    );
  }

  Future<void> test_markdown_isFormattedForDisplay() async {
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
    String [!a^bc!];
    ''';

    final expectedHoverContent = '''
```dart
String abc
```
Type: `String`

*package:test/main.dart*

---
This is a string.

With some [refs] and some
[links](https://www.dartlang.org/)

```dart
print();
```
    '''
        .trim();

    await assertMarkdownContents(content, equals(expectedHoverContent));
  }

  Future<void> test_markdown_simple() => assertMarkdownContents(
        '''
    /// This is a string.
    String [!a^bc!];
    ''',
        contains('This is a string.'),
      );

  Future<void> test_method_startOfParameterList() => assertStringContents(
        '''
    class A {
      /// This is a method.
      String [!abc!]^() {}
    }
    ''',
        contains('This is a method.'),
      );

  Future<void> test_method_startOfTypeParameterList() => assertStringContents(
        '''
    class A {
      /// This is a method.
      String [!abc!]^<T>(T a) {}
    }
    ''',
        contains('This is a method.'),
      );

  Future<void> test_noElement() async {
    final code = TestCode.parse('''
    String abc;

    ^

    int a;
    ''');

    await initialize();
    await openFile(mainFileUri, code.code);
    final hover = await getHover(mainFileUri, code.position.position);
    expect(hover, isNull);
  }

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);
    final hover = await getHover(pubspecFileUri, startOfDocPos);
    expect(hover, isNull);
  }

  Future<void> test_nullableTypes() async {
    final content = '''
    String? [!a^bc!];
    ''';

    final expectedHoverContent = '''
```dart
String? abc
```
Type: `String?`

*package:test/main.dart*
    '''
        .trim();

    await assertStringContents(content, equals(expectedHoverContent));
  }

  Future<void> test_pattern_assignment_left() => assertStringContents(
        '''
void f(String a, String b) {
  (b, [!a^!]) = (a, b);
}
    ''',
        contains('Type: `String`'),
      );

  Future<void> test_pattern_assignment_list() => assertStringContents(
        '''
void f(List<int> x, num a) {
  [[!a^!]] = x;
}
    ''',
        contains('num a'),
      );

  Future<void> test_pattern_assignment_right() => assertStringContents(
        '''
void f(String a, String b) {
  (b, a) = ([!a^!], b);
}
    ''',
        contains('Type: `String`'),
      );

  Future<void> test_pattern_cast_typeName() => assertStringContents(
        '''
void f((num, Object) record) {
  var (i as int, s as [!St^ring!]) = record;
}
    ''',
        contains('class String'),
      );

  Future<void> test_pattern_map() => assertStringContents(
        '''
void f(x) {
  switch (x) {
    case {0: [!Str^ing!] a}:
      break;
  }
}
    ''',
        contains('class String'),
      );

  Future<void> test_pattern_map_typeArguments() => assertStringContents(
        '''
void f(x) {
  switch (x) {
    case <int, [!Str^ing!]>{0: var a}:
      break;
  }
}
    ''',
        contains('class String'),
      );

  Future<void> test_pattern_nullAssert() => assertStringContents(
        '''
void f((int?, int?) position) {
  var ([!x^!]!, y!) = position;
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_pattern_nullCheck() => assertStringContents(
        '''
void f(String? maybeString) {
  switch (maybeString) {
    case var [!s^!]?:
  }
}
    ''',
        contains('Type: `String`'),
      );

  Future<void> test_pattern_object_fieldName() => assertStringContents(
        '''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square([!leng^th!]: var l) => l * l,
  };

class Shape { }
class Square extends Shape {
  /// The length.
  double get length => 0;
}
    ''',
        allOf([
          contains('double get length'),
          contains('The length.'),
        ]),
      );

  Future<void> test_pattern_object_typeName() => assertStringContents(
        '''
double calculateArea(Shape shape) =>
  switch (shape) {
    [!Squ^are!](length: var l) => l * l,
  };

class Shape { }
/// A square.
class Square extends Shape {
  double get length => 0;
}
    ''',
        contains('A square.'),
      );

  Future<void> test_pattern_record_fieldName() => assertStringContents(
        '''
void f(({int foo}) x, num a) {
  ([!fo^o!]: a,) = x;
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_pattern_record_fieldValue() => assertStringContents(
        '''
void f(({int foo}) x, num a) {
  (foo: [!a^!],) = x;
}
    ''',
        contains('Type: `num`'),
      );

  Future<void> test_pattern_record_variable() => assertStringContents(
        '''
void f(({int foo}) x, num a) {
  (foo: a,) = [!x^!];
}
    ''',
        contains('Type: `({int foo})`'),
      );

  Future<void> test_pattern_relational_variable() => assertStringContents(
        '''
String f(int char) {
  const zero = 0;
  return switch (char) {
    == [!ze^ro!] => 'zero'
  };
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_pattern_variable_wildcard() => assertStringContents(
        '''
void f() {
  var a = (1, 2);
  var ([!^_!], _) = a;
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_pattern_variable_wildcard_annotated() =>
      assertStringContents(
        '''
void f() {
  var a = (1, 2);
  var (int [!^_!], _) = a;
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_plainText_simple() => assertPlainTextContents(
        '''
    /// This is a string.
    String [!a^bc!];
    ''',
        contains('This is a string.'),
      );

  Future<void> test_promotedTypes() async {
    final content = '''
void f(aaa) {
  if (aaa is String) {
    print([!aa^a!]);
  }
}
    ''';

    final expectedHoverContent = '''
```dart
dynamic aaa
```
Type: `String`
    '''
        .trim();

    await assertStringContents(content, equals(expectedHoverContent));
  }

  Future<void> test_range_multiLineConstructorCall() => assertStringContents(
        '''
    final a = new [!Str^ing.fromCharCodes!]([
      1,
      2,
    ]);
    ''',
        contains('String String.fromCharCodes('),
      );

  Future<void> test_recordLiteral_named() => assertStringContents(
        r'''
void f(({int f1, int f2}) r) {
  r.[!f^1!];
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_recordLiteral_positional() => assertStringContents(
        r'''
void f((int, int) r) {
  r.[!$^1!];
}
    ''',
        contains('Type: `int`'),
      );

  Future<void> test_recordType_parameter() => assertStringContents(
        '''
void f(([!dou^ble!], double) param) {
  return (1.0, 1.0);
}
    ''',
        contains('class double'),
      );

  Future<void> test_recordType_return() => assertStringContents(
        '''
([!dou^ble!], double) f() {
  return (1.0, 1.0);
}
    ''',
        contains('class double'),
      );

  Future<void> test_signatureFormatting_multiLine() => assertStringContents(
        '''
    class Foo {
      Foo(String arg1, String arg2, [String arg3]);
    }

    void f() {
      var a = [!Fo^o!]();
    }
    ''',
        startsWith('''
```dart
(new) Foo Foo(
  String arg1,
  String arg2, [
  String arg3,
])
```'''),
      );

  Future<void> test_signatureFormatting_singleLine() => assertStringContents(
        '''
    class Foo {
      Foo(String a, String b);
    }

    void f() {
      var a = [!Fo^o!]();
    }
    ''',
        startsWith('''
```dart
(new) Foo Foo(String a, String b)
```'''),
      );

  Future<void> test_string_noDocComment() async {
    final content = '''
    String [!a^bc!];
    ''';

    final expectedHoverContent = '''
```dart
String abc
```
Type: `String`

*package:test/main.dart*
    '''
        .trim();

    await assertStringContents(content, equals(expectedHoverContent));
  }

  Future<void> test_string_reflectsLatestEdits() async {
    final original = TestCode.parse('''
    /// Original string.
    String [!a^bc!];
    ''');
    final updated = TestCode.parse('''
    /// Updated string.
    String [!a^bc!];
    ''');

    await initialize();
    await openFile(mainFileUri, original.code);
    var hover = await getHover(mainFileUri, original.position.position);
    expect(hover, isNotNull);
    var contents = _getStringContents(hover!);
    expect(contents, contains('Original'));

    await replaceFile(222, mainFileUri, updated.code);
    hover = await getHover(mainFileUri, updated.position.position);
    expect(hover, isNotNull);
    contents = _getStringContents(hover!);
    expect(contents, contains('Updated'));
  }

  Future<void> test_string_simple() async {
    final content = '''
/// This is a string.
String [!a^bc!];
''';
    final expected = '''
```dart
String abc
```
Type: `String`

*package:test/main.dart*

---
This is a string.''';
    await assertStringContents(content, equals(expected));
  }

  Future<void> test_unopenFile() async {
    final content = '''
/// This is a string.
String [!a^bc!];
''';
    final expected = '''
```dart
String abc
```
Type: `String`

*package:test/main.dart*

---
This is a string.''';
    await assertStringContents(withOpenFile: false, content, equals(expected));
  }

  MarkupContent _getMarkupContents(Hover hover) {
    return hover.contents.map(
      (t1) => t1,
      (t2) => throw 'Hover contents were String, not MarkupContent',
    );
  }

  String _getStringContents(Hover hover) {
    return hover.contents.map(
      (t1) => throw 'Hover contents were MarkupContent, not String',
      (t2) => t2,
    );
  }
}
