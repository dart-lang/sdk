// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionRangeTest);
  });
}

/// Additional tests are in
///
/// test/src/computer/selection_range_computer_test.dart
@reflectiveTest
class SelectionRangeTest extends AbstractLspAnalysisServerTest {
  Future<void> test_dotShorthand_constructorInvocation() async {
    var content = '''
class A {}
void f() {
  A a = .^new();
}
''';

    await verifySelectionRanges(content, [
      'new',
      '.new()',
      'a = .new()',
      'A a = .new()',
      'A a = .new();',
      '{\n  A a = .new();\n}',
      '() {\n  A a = .new();\n}',
      'void f() {\n  A a = .new();\n}',
    ]);
  }

  Future<void> test_dotShorthand_methodInvocation() async {
    var content = '''
class A {
  static A method() => A();
}
void f() {
  A a = .me^thod();
}
''';

    await verifySelectionRanges(content, [
      'method',
      '.method()',
      'a = .method()',
      'A a = .method()',
      'A a = .method();',
      '{\n  A a = .method();\n}',
      '() {\n  A a = .method();\n}',
      'void f() {\n  A a = .method();\n}',
    ]);
  }

  Future<void> test_dotShorthand_propertyAccess() async {
    var content = '''
enum A { a }
void f() {
  A a = .^a;
}
''';

    await verifySelectionRanges(content, [
      'a',
      '.a',
      'a = .a',
      'A a = .a',
      'A a = .a;',
      '{\n  A a = .a;\n}',
      '() {\n  A a = .a;\n}',
      'void f() {\n  A a = .a;\n}',
    ]);
  }

  Future<void> test_emptyBody_class() async {
    failTestOnErrorDiagnostic = false; // Enum with no constant

    var content = '''
class ^C;
''';

    await verifySelectionRanges(content, ['class C;']);
  }

  Future<void> test_emptyBody_enum() async {
    failTestOnErrorDiagnostic = false; // Enum with no constant

    var content = '''
enum ^E;
''';

    await verifySelectionRanges(content, ['enum E;']);
  }

  Future<void> test_emptyBody_extension() async {
    failTestOnErrorDiagnostic = false; // Enum with no constant

    var content = '''
extension Ex^ on String;
''';

    await verifySelectionRanges(content, ['extension Ex on String;']);
  }

  Future<void> test_emptyBody_mixin() async {
    var content = '''
mixin Fo^o;
''';

    await verifySelectionRanges(content, ['mixin Foo;']);
  }

  Future<void> test_multiple() async {
    var code = TestCode.parseNormalized('''
class Foo {
  void a() => /*0*/0;
  void b() => /*1*/1;
}
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var lineInfo = LineInfo.fromContent(code.code);

    // Send a request for two positions.
    var regions = await getManySelectionRanges(mainFileUri, [
      code.positions[0].position,
      code.positions[1].position,
    ]);
    expect(regions!.length, equals(2));
    var firstTexts = _getSelectionRangeText(
      lineInfo,
      code.code,
      regions[0],
    ).toList();
    var secondTexts = _getSelectionRangeText(
      lineInfo,
      code.code,
      regions[1],
    ).toList();

    expect(
      firstTexts,
      equalsNormalized([
        '0',
        '=> 0;',
        'void a() => 0;',
        '{\n  void a() => 0;\n  void b() => 1;\n}',
        'class Foo {\n  void a() => 0;\n  void b() => 1;\n}',
      ]),
    );
    expect(
      secondTexts,
      equalsNormalized([
        '1',
        '=> 1;',
        'void b() => 1;',
        '{\n  void a() => 0;\n  void b() => 1;\n}',
        'class Foo {\n  void a() => 0;\n  void b() => 1;\n}',
      ]),
    );
  }

  Future<void> test_nullAwareElements_inList() async {
    var content = '''
class Foo<T> {
  List<int> a(String b) {
    return [?(1 ^+ 2) * 3];
  }
}
''';

    await verifySelectionRanges(content, [
      '1 + 2',
      '(1 + 2)',
      '(1 + 2) * 3',
      '?(1 + 2) * 3',
      '[?(1 + 2) * 3]',
      'return [?(1 + 2) * 3];',
      '{\n    return [?(1 + 2) * 3];\n  }',
      'List<int> a(String b) {\n    return [?(1 + 2) * 3];\n  }',
      '{\n  List<int> a(String b) {\n    return [?(1 + 2) * 3];\n  }\n}',
      'class Foo<T> {\n  List<int> a(String b) {\n    return [?(1 + 2) * 3];\n  }\n}',
    ]);
  }

  Future<void> test_nullAwareElements_inMapKey() async {
    var content = '''
class Foo<T> {
  Map<int, String> a(String b) {
    return {?(1 ^+ 2) * 3: b};
  }
}
''';

    await verifySelectionRanges(content, [
      '1 + 2',
      '(1 + 2)',
      '(1 + 2) * 3',
      '?(1 + 2) * 3: b',
      '{?(1 + 2) * 3: b}',
      'return {?(1 + 2) * 3: b};',
      '{\n    return {?(1 + 2) * 3: b};\n  }',
      'Map<int, String> a(String b) {\n    return {?(1 + 2) * 3: b};\n  }',
      '{\n  Map<int, String> a(String b) {\n    return {?(1 + 2) * 3: b};\n  }\n}',
      'class Foo<T> {\n  Map<int, String> a(String b) {\n    return {?(1 + 2) * 3: b};\n  }\n}',
    ]);
  }

  Future<void> test_nullAwareElements_inMapValue() async {
    var content = '''
class Foo<T> {
  Map<String, int> a(String b) {
    return {b: ?(1 ^+ 2) * 3};
  }
}
''';

    await verifySelectionRanges(content, [
      '1 + 2',
      '(1 + 2)',
      '(1 + 2) * 3',
      'b: ?(1 + 2) * 3',
      '{b: ?(1 + 2) * 3}',
      'return {b: ?(1 + 2) * 3};',
      '{\n    return {b: ?(1 + 2) * 3};\n  }',
      'Map<String, int> a(String b) {\n    return {b: ?(1 + 2) * 3};\n  }',
      '{\n  Map<String, int> a(String b) {\n    return {b: ?(1 + 2) * 3};\n  }\n}',
      'class Foo<T> {\n  Map<String, int> a(String b) {\n    return {b: ?(1 + 2) * 3};\n  }\n}',
    ]);
  }

  Future<void> test_nullAwareElements_inSet() async {
    var content = '''
class Foo<T> {
  Set<int> a(String b) {
    return {?(1 ^+ 2) * 3};
  }
}
''';

    await verifySelectionRanges(content, [
      '1 + 2',
      '(1 + 2)',
      '(1 + 2) * 3',
      '?(1 + 2) * 3',
      '{?(1 + 2) * 3}',
      'return {?(1 + 2) * 3};',
      '{\n    return {?(1 + 2) * 3};\n  }',
      'Set<int> a(String b) {\n    return {?(1 + 2) * 3};\n  }',
      '{\n  Set<int> a(String b) {\n    return {?(1 + 2) * 3};\n  }\n}',
      'class Foo<T> {\n  Set<int> a(String b) {\n    return {?(1 + 2) * 3};\n  }\n}',
    ]);
  }

  Future<void> test_primaryConstructor_body() async {
    var content = '''
class A(int a) {
  this {
    print(^a);
  }
}
''';

    await verifySelectionRanges(content, [
      'a',
      '(a)',
      'print(a)',
      'print(a);',
      '{\n    print(a);\n  }',
      'this {\n    print(a);\n  }',
      '{\n  this {\n    print(a);\n  }\n}',
      'class A(int a) {\n  this {\n    print(a);\n  }\n}',
    ]);
  }

  Future<void> test_primaryConstructor_declaration() async {
    var content = '''
class A(final int a, { final i^nt b = 0 });
''';

    await verifySelectionRanges(content, [
      'int',
      'final int b',
      'final int b = 0',
      '(final int a, { final int b = 0 })',
      'A(final int a, { final int b = 0 })',
      'class A(final int a, { final int b = 0 });',
    ]);
  }

  Future<void> test_single() async {
    var content = '''
class Foo<T> {
  void a(String b) {
    print((1 ^+ 2) * 3);
  }
}
''';

    await verifySelectionRanges(content, [
      '1 + 2',
      '(1 + 2)',
      '(1 + 2) * 3',
      '((1 + 2) * 3)',
      'print((1 + 2) * 3)',
      'print((1 + 2) * 3);',
      '{\n    print((1 + 2) * 3);\n  }',
      'void a(String b) {\n    print((1 + 2) * 3);\n  }',
      '{\n  void a(String b) {\n    print((1 + 2) * 3);\n  }\n}',
      'class Foo<T> {\n  void a(String b) {\n    print((1 + 2) * 3);\n  }\n}',
    ]);
  }

  Future<void> verifySelectionRanges(
    String content,
    List<String> expectedRanges,
  ) async {
    var code = TestCode.parseNormalized(content);

    await initialize();
    await openFile(mainFileUri, code.code);
    var lineInfo = LineInfo.fromContent(code.code);

    var region = await getSelectionRanges(mainFileUri, code.position.position);
    var regionTexts = _getSelectionRangeText(
      lineInfo,
      code.code,
      region,
    ).toList();

    expect(regionTexts, equalsNormalized(expectedRanges));
  }

  Iterable<String> _getSelectionRangeText(
    LineInfo lineInfo,
    String content,
    SelectionRange range,
  ) sync* {
    yield _rangeOfText(lineInfo, content, range.range);
    var parent = range.parent;
    if (parent != null) {
      yield* _getSelectionRangeText(lineInfo, content, parent);
    }
  }

  String _rangeOfText(LineInfo lineInfo, String content, Range range) {
    var startPos = range.start;
    var endPos = range.end;
    var start = lineInfo.getOffsetOfLine(startPos.line) + startPos.character;
    var end = lineInfo.getOffsetOfLine(endPos.line) + endPos.character;
    return content.substring(start, end);
  }
}
