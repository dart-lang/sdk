// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_selection_ranges.dart';
import 'package:analyzer/dart/analysis/results.dart';
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
    final content = '''
class Foo {
  Foo({String arg1});
}
final foo = Foo(arg1: "test");
''';
    final offset = content.indexOf('test');

    final regions = await _computeSelectionRanges(content, offset);
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
    final content = 'class Foo<T> {}';
    final offset = 0;

    final regions = await _computeSelectionRanges(content, offset);
    _expectRegions(regions, content, ['class Foo<T> {}']);
  }

  Future<void> test_class_fields() async {
    final content = '''
class Foo<T> {
  String a = 'test';
}
''';
    final offset = content.indexOf('String');

    final regions = await _computeSelectionRanges(content, offset);
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
    final content = '''
class Foo {
  Foo(String b);
}
final foo = Foo("test");
''';
    final offset = content.indexOf('test');

    final regions = await _computeSelectionRanges(content, offset);
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

  Future<void> test_method() async {
    final content = '''
class Foo<T> {
  void a(String b) {
    print((1 + 2) * 3);
  }
}
''';
    final offset = content.indexOf('+');

    final regions = await _computeSelectionRanges(content, offset);
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
    final content = '''
class Foo<T> {
  void a(String b) => print((1 + 2) * 3);
}
''';
    final offset = content.indexOf('+');

    final regions = await _computeSelectionRanges(content, offset);
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

  Future<void> test_topLevelFunction() async {
    final content = '''
void a(String b) {
  print((1 + 2) * 3);
}
''';
    final offset = content.indexOf('+');

    final regions = await _computeSelectionRanges(content, offset);
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

  Future<void> test_whitespace() async {
    final content = '    class Foo {}';
    final offset = 0;

    final regions = await _computeSelectionRanges(content, offset);
    expect(regions, isEmpty);
  }

  Future<List<SelectionRange>?> _computeSelectionRanges(
      String sourceContent, int offset) async {
    newFile(sourcePath, content: sourceContent);
    var result =
        await session.getResolvedUnit(sourcePath) as ResolvedUnitResult;
    var computer = DartSelectionRangeComputer(result.unit, offset);
    return computer.compute();
  }

  /// Checks the text of [regions] against [expected].
  void _expectRegions(
      List<SelectionRange>? regions, String content, List<String> expected) {
    final actual = regions!
        .map((region) =>
            content.substring(region.offset, region.offset + region.length))
        .toList();

    expect(actual, equals(expected));
  }
}
