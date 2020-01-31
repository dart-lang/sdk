// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportedElementsComputerTest);
  });
}

@reflectiveTest
class ImportedElementsComputerTest extends AbstractContextTest {
  String sourcePath;

  List<ImportedElements> importedElements;

  void assertElements(List<ImportedElements> expectedElementsList) {
    expect(importedElements, hasLength(expectedElementsList.length));
    for (ImportedElements expectedElements in expectedElementsList) {
      String expectedPath = convertPath(expectedElements.path);
      bool found = false;
      for (ImportedElements actualElements in importedElements) {
        if (expectedPath == actualElements.path &&
            actualElements.prefix == expectedElements.prefix) {
          expect(actualElements.elements,
              unorderedEquals(expectedElements.elements));
          found = true;
          break;
        }
      }
      if (!found) {
        fail('Expected elements from $expectedPath, but none found.');
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('/home/test/lib/test.dart');
  }

  Future<void> test_dartAsync_noPrefix() async {
    String selection = 'Future<String> f = null;';
    String content = '''
import 'dart:async';
printer() {
  $selection
  print(await f);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
      ImportedElements('/sdk/lib/async/async.dart', '', ['Future']),
    ]);
  }

  Future<void> test_dartAsync_prefix() async {
    String selection = 'a.Future<String> f = null;';
    String content = '''
import 'dart:async' as a;
printer() {
  $selection
  print(await f);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
      ImportedElements('/sdk/lib/async/async.dart', 'a', ['Future']),
    ]);
  }

  Future<void> test_dartCore_noPrefix() async {
    String selection = "String s = '';";
    String content = '''
blankLine() {
  $selection
  print(s);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
    ]);
  }

  Future<void> test_dartCore_prefix() async {
    String selection = "core.String s = '';";
    String content = '''
import 'dart:core' as core;
blankLine() {
  $selection
  print(s);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', 'core', ['String']),
    ]);
  }

  Future<void> test_dartMath_noPrefix() async {
    String selection = 'new Random();';
    String content = '''
import 'dart:math';
bool randomBool() {
  Random r = $selection
  return r.nextBool();
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/math/math.dart', '', ['Random']),
    ]);
  }

  Future<void> test_import_simple() async {
    String selection = "import 'dart:math';";
    String content = '''
$selection
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_import_simple_show() async {
    String selection = "import 'dart:math' show Random;";
    String content = '''
$selection
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_multiple() async {
    String selection = r'''
main() {
  Random r = new Random();
  String s = r.nextBool().toString();
  print(s);
}
''';
    String content = '''
import 'dart:math';

$selection
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String', 'print']),
      ImportedElements('/sdk/lib/math/math.dart', '', ['Random']),
    ]);
  }

  Future<void> test_none_comment() async {
    String selection = 'comment';
    String content = '''
// Method $selection.
blankLine() {
  print('');
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_constructorDeclarationReturnType() async {
    String selection = r'''
class A {
  A();
  A.named();
}
''';
    String content = '''
$selection
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_partialNames() async {
    String selection = 'x + y';
    String content = '''
plusThree(int xx) {
  int yy = 2;
  print(x${selection}y);
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_wholeNames() async {
    String selection = 'x + y + 1';
    String content = '''
plusThree(int x) {
  int y = 2;
  print($selection);
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_package_multipleInSame() async {
    addPackageFile('foo', 'foo.dart', '''
class A {
  static String a = '';
}
class B {
  static String b = '';
}
''');
    String selection = 'A.a + B.b';
    String content = '''
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', '', ['A', 'B']),
    ]);
  }

  Future<void> test_package_noPrefix() async {
    addPackageFile('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = 'Foo.first';
    String content = '''
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_class() async {
    addPackageFile('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = 'f.Foo.first';
    String content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', 'f', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_function() async {
    addPackageFile('foo', 'foo.dart', '''
String foo() => '';
''');
    String selection = 'f.foo()';
    String content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_getter() async {
    addPackageFile('foo', 'foo.dart', '''
String foo = '';
''');
    String selection = 'f.foo';
    String content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_setter() async {
    addPackageFile('foo', 'foo.dart', '''
String foo = '';
''');
    String selection = 'f.foo';
    String content = '''
import 'package:foo/foo.dart' as f;
main() {
  $selection = '';
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', 'f', ['foo=']),
    ]);
  }

  Future<void> test_package_prefix_unselected() async {
    addPackageFile('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = 'Foo.first';
    String content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print(f.$selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefixedAndNot() async {
    addPackageFile('foo', 'foo.dart', '''
class Foo {
  static String first = '';
  static String second = '';
}
''');
    String selection = 'f.Foo.first + Foo.second';
    String content = '''
import 'package:foo/foo.dart';
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements('/.pub-cache/foo/lib/foo.dart', '', ['Foo']),
      ImportedElements('/.pub-cache/foo/lib/foo.dart', 'f', ['Foo']),
    ]);
  }

  Future<void> test_self() async {
    String selection = 'A parent;';
    String content = '''
class A {
  $selection
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(sourcePath, '', ['A']),
    ]);
  }

  Future<void> test_wholeFile_noImports() async {
    String content = '''
blankLine() {
  String s = '';
  print(s);
}
''';
    await _computeElements(content, content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String', 'print']),
    ]);
  }

  Future<void> test_wholeFile_withImports() async {
    String content = '''
import 'dart:math';
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
''';
    await _computeElements(content, content);
    expect(importedElements, hasLength(0));
  }

  Future<void> _computeElements(String content, String selection) async {
    // TODO(brianwilkerson) Automatically extract the selection from the content.
    newFile(sourcePath, content: content);
    ResolvedUnitResult result = await session.getResolvedUnit(sourcePath);
    ImportedElementsComputer computer = ImportedElementsComputer(
        result.unit, content.indexOf(selection), selection.length);
    importedElements = computer.compute();
  }
}
