// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
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
  late String sourcePath;

  late List<ImportedElements> importedElements;

  void assertElements(List<ImportedElements> expectedElementsList) {
    expect(importedElements, hasLength(expectedElementsList.length));
    for (var expectedElements in expectedElementsList) {
      var expectedPath = convertPath(expectedElements.path);
      var found = false;
      for (var actualElements in importedElements) {
        if (expectedPath == actualElements.path &&
            actualElements.prefix == expectedElements.prefix) {
          expect(
            actualElements.elements,
            unorderedEquals(expectedElements.elements),
          );
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
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_dartAsync_noPrefix() async {
    var content = '''
import 'dart:async';
printer() {
  [!Future<String> f = null;!]
  print(await f);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
      ImportedElements('/sdk/lib/async/async.dart', '', ['Future']),
    ]);
  }

  Future<void> test_dartAsync_prefix() async {
    var content = '''
import 'dart:async' as a;
printer() {
  [!a.Future<String> f = null;!]
  print(await f);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
      ImportedElements('/sdk/lib/async/async.dart', 'a', ['Future']),
    ]);
  }

  Future<void> test_dartCore_noPrefix() async {
    var content = '''
blankLine() {
  [!String s = '';!]
  print(s);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String']),
    ]);
  }

  Future<void> test_dartCore_prefix() async {
    var content = '''
import 'dart:core' as core;
blankLine() {
  [!core.String s = '';!]
  print(s);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', 'core', ['String']),
    ]);
  }

  Future<void> test_dartMath_noPrefix() async {
    var content = '''
import 'dart:math';
bool randomBool() {
  Random r = [!new Random();!]
  return r.nextBool();
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/math/math.dart', '', ['Random']),
    ]);
  }

  Future<void> test_import_simple() async {
    var content = '''
[!import 'dart:math';!]
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_import_simple_show() async {
    var content = '''
[!import 'dart:math' show Random;!]
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_multiple() async {
    var content = '''
import 'dart:math';

[!
void f() {
  Random r = new Random();
  String s = r.nextBool().toString();
  print(s);
}
!]
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String', 'print']),
      ImportedElements('/sdk/lib/math/math.dart', '', ['Random']),
    ]);
  }

  Future<void> test_none_comment() async {
    var content = '''
// Method [!comment!].
blankLine() {
  print('');
}
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_constructorDeclarationReturnType() async {
    var content = '''
[!
class A {
  A();
  A.named();
}
!]
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_partialNames() async {
    var content = '''
plusThree(int xx) {
  int yy = 2;
  print(x[!x + y!]y);
}
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_none_wholeNames() async {
    var content = '''
plusThree(int x) {
  int y = 2;
  print([!x + y + 1!]);
}
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> test_package_multipleInSame() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
class A {
  static String a = '';
}
class B {
  static String b = '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart';
blankLine() {
  print([!A.a + B.b!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, '', ['A', 'B']),
    ]);
  }

  Future<void> test_package_noPrefix() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart';
blankLine() {
  print([!Foo.first!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_class() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print([!f.Foo.first!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, 'f', ['Foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_function() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
String foo() => '';
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print([!f.foo()!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_getter() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
String foo = '';
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print([!f.foo!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, 'f', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_selected_setter() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
String foo = '';
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart' as prefix;
void f() {
  [!prefix.foo!] = '';
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, 'prefix', ['foo']),
    ]);
  }

  Future<void> test_package_prefix_unselected() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
class Foo {
  static String first = '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart' as f;
blankLine() {
  print(f.[!Foo.first!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
    ]);
  }

  Future<void> test_package_prefixedAndNot() async {
    var fooPath = '$workspaceRootPath/foo/lib/foo.dart';
    newFile(fooPath, '''
class Foo {
  static String first = '';
  static String second = '';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
    );

    var content = '''
import 'package:foo/foo.dart';
import 'package:foo/foo.dart' as f;
blankLine() {
  print([!f.Foo.first + Foo.second!]);
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(fooPath, '', ['Foo']),
      ImportedElements(fooPath, 'f', ['Foo']),
    ]);
  }

  Future<void> test_self() async {
    var content = '''
class A {
  [!A parent;!]
}
''';
    await _computeElements(content);
    assertElements([
      ImportedElements(sourcePath, '', ['A']),
    ]);
  }

  Future<void> test_wholeFile_noImports() async {
    var content = '''
[!
blankLine() {
  String s = '';
  print(s);
}
!]
''';
    await _computeElements(content);
    assertElements([
      ImportedElements('/sdk/lib/core/core.dart', '', ['String', 'print']),
    ]);
  }

  Future<void> test_wholeFile_withImports() async {
    var content = '''
[!
import 'dart:math';
bool randomBool() {
  Random r = new Random();
  return r.nextBool();
}
!]
''';
    await _computeElements(content);
    expect(importedElements, hasLength(0));
  }

  Future<void> _computeElements(String content) async {
    var code = TestCode.parseNormalized(content);
    var file = newFile(sourcePath, code.code);
    var result = await getResolvedUnit(file);
    var computer = ImportedElementsComputer(
      result.unit,
      code.range.sourceRange.offset,
      code.range.sourceRange.length,
    );
    importedElements = computer.compute();
  }
}
