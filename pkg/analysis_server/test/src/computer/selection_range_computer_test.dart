// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_selection_ranges.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionRangeComputerTest);
  });
}

@reflectiveTest
class SelectionRangeComputerTest extends AbstractContextTest {
  late String sourcePath;

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_arguments() async {
    final content = TestCode.parse('''
class Foo {
  Foo({String arg1});
}
final foo = Foo(arg1: "^test");
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '"test"',
        'arg1: "test"',
        '(arg1: "test")',
        'Foo(arg1: "test")',
        'foo = Foo(arg1: "test")',
        'final foo = Foo(arg1: "test")',
        'final foo = Foo(arg1: "test");',
      ],
    );
  }

  Future<void> test_class_definition() async {
    final content = TestCode.parse('^class Foo<T> {}');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(regions, content, ['class Foo<T> {}']);
  }

  Future<void> test_class_fields() async {
    final content = TestCode.parse('''
class Foo<T> {
  ^String a = 'test';
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        'String',
        "String a = 'test'",
        "String a = 'test';",
        "class Foo<T> {\n  String a = 'test';\n}",
      ],
    );
  }

  Future<void> test_constructorCall() async {
    final content = TestCode.parse('''
class Foo {
  Foo(String b);
}
final foo = Foo("^test");
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '"test"',
        '("test")',
        'Foo("test")',
        'foo = Foo("test")',
        'final foo = Foo("test")',
        'final foo = Foo("test");',
      ],
    );
  }

  Future<void> test_extensionType() async {
    final content = TestCode.parse('''
extension type E<T>(int it) {
  void void foo() {
    (1 ^+ 2) * 3;
  }
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '1 + 2',
        '(1 + 2)',
        '(1 + 2) * 3',
        '(1 + 2) * 3;',
        '{\n'
            '    (1 + 2) * 3;\n'
            '  }',
        'void foo() {\n'
            '    (1 + 2) * 3;\n'
            '  }',
        'extension type E<T>(int it) {\n'
            '  void void foo() {\n'
            '    (1 + 2) * 3;\n'
            '  }\n'
            '}',
      ],
    );
  }

  Future<void> test_field_recordType() async {
    final content = TestCode.parse('''
class C<T> {
  (^int, int) r = (0, 1);
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        'int',
        '(int, int)',
        '(int, int) r = (0, 1)',
        '(int, int) r = (0, 1);',
        'class C<T> {\n  (int, int) r = (0, 1);\n}',
      ],
    );
  }

  Future<void> test_method() async {
    final content = TestCode.parse('''
class Foo<T> {
  void a(String b) {
    print((1 ^+ 2) * 3);
  }
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '1 + 2',
        '(1 + 2)',
        '(1 + 2) * 3',
        '((1 + 2) * 3)',
        'print((1 + 2) * 3)',
        'print((1 + 2) * 3);',
        '{\n    print((1 + 2) * 3);\n  }',
        'void a(String b) {\n    print((1 + 2) * 3);\n  }',
        'class Foo<T> {\n  void a(String b) {\n    print((1 + 2) * 3);\n  }\n}',
      ],
    );
  }

  Future<void> test_methodLambda() async {
    final content = TestCode.parse('''
class Foo<T> {
  void a(String b) => print((1 ^+ 2) * 3);
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '1 + 2',
        '(1 + 2)',
        '(1 + 2) * 3',
        '((1 + 2) * 3)',
        'print((1 + 2) * 3)',
        '=> print((1 + 2) * 3);',
        'void a(String b) => print((1 + 2) * 3);',
        'class Foo<T> {\n  void a(String b) => print((1 + 2) * 3);\n}',
      ],
    );
  }

  Future<void> test_pattern_relational() async {
    final content = TestCode.parse('''
final a = switch(123) {
  == ^0 => 'zero',
  _ => 'other'
};
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(regions, content, [
      '0',
      '== 0',
      '== 0 => \'zero\'',
      'switch(123) {\n'
          '  == 0 => \'zero\',\n'
          '  _ => \'other\'\n'
          '}',
      'a = switch(123) {\n'
          '  == 0 => \'zero\',\n'
          '  _ => \'other\'\n'
          '}',
      'final a = switch(123) {\n'
          '  == 0 => \'zero\',\n'
          '  _ => \'other\'\n'
          '}',
      'final a = switch(123) {\n'
          '  == 0 => \'zero\',\n'
          '  _ => \'other\'\n'
          '};'
    ]);
  }

  Future<void> test_pattern_types() async {
    final content = TestCode.parse('''
final a = switch (Object()) {
  Square(length: v^ar l) => l * l,
  Circle(radius: var r) => math.pi * r * r
};

class Square {
  final int length;
  Square(this.length);
}

class Circle {
  final int length;
  Circle(this.radius);
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(regions, content, [
      'var l',
      'length: var l',
      'Square(length: var l)',
      'Square(length: var l) => l * l',
      'switch (Object()) {\n'
          '  Square(length: var l) => l * l,\n'
          '  Circle(radius: var r) => math.pi * r * r\n'
          '}',
      'a = switch (Object()) {\n'
          '  Square(length: var l) => l * l,\n'
          '  Circle(radius: var r) => math.pi * r * r\n'
          '}',
      'final a = switch (Object()) {\n'
          '  Square(length: var l) => l * l,\n'
          '  Circle(radius: var r) => math.pi * r * r\n'
          '}',
      'final a = switch (Object()) {\n'
          '  Square(length: var l) => l * l,\n'
          '  Circle(radius: var r) => math.pi * r * r\n'
          '};'
    ]);
  }

  Future<void> test_topLevelFunction() async {
    final content = TestCode.parse('''
void a(String b) {
  print((1 ^+ 2) * 3);
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        '1 + 2',
        '(1 + 2)',
        '(1 + 2) * 3',
        '((1 + 2) * 3)',
        'print((1 + 2) * 3)',
        'print((1 + 2) * 3);',
        '{\n  print((1 + 2) * 3);\n}',
        '(String b) {\n  print((1 + 2) * 3);\n}',
        'void a(String b) {\n  print((1 + 2) * 3);\n}',
      ],
    );
  }

  Future<void> test_topLevelFunction_record() async {
    final content = TestCode.parse('''
void f() {
  var r = (x: 3, ^y: 2);
}
''');

    final regions = await _computeSelectionRanges(content);
    _expectRegions(
      regions,
      content,
      [
        'y',
        'y:',
        'y: 2',
        '(x: 3, y: 2)',
        'r = (x: 3, y: 2)',
        'var r = (x: 3, y: 2)',
        'var r = (x: 3, y: 2);',
        '{\n  var r = (x: 3, y: 2);\n}',
        '() {\n  var r = (x: 3, y: 2);\n}',
        'void f() {\n  var r = (x: 3, y: 2);\n}',
      ],
    );
  }

  Future<void> test_whitespace() async {
    final content = TestCode.parse('^    class Foo {}');

    final regions = await _computeSelectionRanges(content);
    expect(regions, isEmpty);
  }

  Future<List<SelectionRange>?> _computeSelectionRanges(TestCode code) async {
    final file = newFile(sourcePath, code.code);
    var result = await getResolvedUnit(file);
    var computer =
        DartSelectionRangeComputer(result.unit, code.position.offset);
    return computer.compute();
  }

  /// Checks the text of [regions] against [expected].
  void _expectRegions(
      List<SelectionRange>? regions, TestCode code, List<String> expected) {
    final actual = regions!
        .map((region) =>
            code.code.substring(region.offset, region.offset + region.length))
        .toList();

    expect(actual, equals(expected));
  }
}
