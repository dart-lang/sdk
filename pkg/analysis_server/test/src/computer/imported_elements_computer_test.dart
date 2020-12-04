// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';
import '../../services/refactoring/abstract_rename.dart';

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
    for (var expectedElements in expectedElementsList) {
      var expectedPath = convertPath(expectedElements.path);
      var found = false;
      for (var actualElements in importedElements) {
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
    var selection = 'Future<String> f = null;';
    var content = '''
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
    var selection = 'a.Future<String> f = null;';
    var content = '''
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
    var selection = "String s = '';";
    var content = '''
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
    var selection = "core.String s = '';";
    var content = '''
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
    var selection = 'new Random();';
    var content = '''
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
    var selection = "import 'dart:math';";
    var content = '''
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
    var selection = "import 'dart:math' show Random;";
    var content = '''
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
    var selection = r'''
main() {
  Random r = new Random();
  String s = r.nextBool().toString();
  print(s);
}
''';
    var content = '''
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
    var selection = 'comment';
    var content = '''
// Method $selection.
blankLine() {
  print('');
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_constructorDeclarationReturnType() async {
    var selection = r'''
class A {
  A();
  A.named();
}
''';
    var content = '''
$selection
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_partialNames() async {
    var selection = 'x + y';
    var content = '''
plusThree(int xx) {
  int yy = 2;
  print(x${selection}y);
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_wholeNames() async {
    var selection = 'x + y + 1';
    var content = '''
plusThree(int x) {
  int y = 2;
  print($selection);
}
''';
    await _computeElements(content, selection);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_package_multipleInSame() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
class A {
  static String a = '';
}
class B {
  static String b = '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'A.a + B.b';
    var content = '''
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, '', ['A', 'B']),
    ]);
  }

  Future<void> test_package_noPrefix() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'Foo.first';
    var content = '''
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_class() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'f.Foo.first';
    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, 'f', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_function() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
String foo() => '';
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'f.foo()';
    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_getter() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
String foo = '';
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'f.foo';
    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_setter() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
String foo = '';
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'f.foo';
    var content = '''
import 'package:foo/foo.dart' as f;
main() {
  $selection = '';
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, 'f', ['foo=']),
    ]);
  }

  Future<void> test_package_prefix_unselected() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'Foo.first';
    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print(f.$selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefixedAndNot() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, content: '''
class Foo {
  static String first = '';
  static String second = '';
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var selection = 'f.Foo.first + Foo.second';
    var content = '''
import 'package:foo/foo.dart';
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
''';
    await _computeElements(content, selection);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
      ImportedElements(fooPath, 'f', ['Foo']),
    ]);
  }

  Future<void> test_self() async {
    var selection = 'A parent;';
    var content = '''
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
    var content = '''
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
    var content = '''
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
    var result = await session.getResolvedUnit(sourcePath);
    var computer = ImportedElementsComputer(
        result.unit, content.indexOf(selection), selection.length);
    importedElements = computer.compute();
  }
}
