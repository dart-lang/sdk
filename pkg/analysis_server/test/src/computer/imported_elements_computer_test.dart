// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportElementsComputerTest);
  });
}

@reflectiveTest
class ImportElementsComputerTest extends AbstractContextTest {
  String sourcePath;

  setUp() {
    super.setUp();
    sourcePath = provider.convertPath('/p/lib/source.dart');
  }

  test_dartAsync_noPrefix() async {
    String selection = "Future<String> f = null;";
    String content = """
import 'dart:async';
printer() {
  $selection
  print(await f);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(2));
    ImportedElements elements1 = elementsList[0];
    ImportedElements elements2 = elementsList[1];
    ImportedElements asyncElements;
    ImportedElements coreElements;
    if (elements1.path == '/lib/core/core.dart') {
      coreElements = elements1;
      asyncElements = elements2;
    } else {
      coreElements = elements2;
      asyncElements = elements1;
    }
    expect(coreElements, isNotNull);
    expect(coreElements.path, '/lib/core/core.dart');
    expect(coreElements.prefix, '');
    expect(coreElements.elements, unorderedEquals(['String']));

    expect(asyncElements, isNotNull);
    expect(asyncElements.path, '/lib/async/async.dart');
    expect(asyncElements.prefix, '');
    expect(asyncElements.elements, unorderedEquals(['Future']));
  }

  test_dartAsync_prefix() async {
    String selection = "a.Future<String> f = null;";
    String content = """
import 'dart:async' as a;
printer() {
  $selection
  print(await f);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(2));
    ImportedElements elements1 = elementsList[0];
    ImportedElements elements2 = elementsList[1];
    ImportedElements asyncElements;
    ImportedElements coreElements;
    if (elements1.path == '/lib/core/core.dart') {
      coreElements = elements1;
      asyncElements = elements2;
    } else {
      coreElements = elements2;
      asyncElements = elements1;
    }
    expect(coreElements, isNotNull);
    expect(coreElements.path, '/lib/core/core.dart');
    expect(coreElements.prefix, '');
    expect(coreElements.elements, unorderedEquals(['String']));

    expect(asyncElements, isNotNull);
    expect(asyncElements.path, '/lib/async/async.dart');
    expect(asyncElements.prefix, 'a');
    expect(asyncElements.elements, unorderedEquals(['Future']));
  }

  test_dartCore_noPrefix() async {
    String selection = "String s = '';";
    String content = """
blankLine() {
  $selection
  print(s);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/lib/core/core.dart');
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['String']));
  }

  test_dartCore_prefix() async {
    String selection = "core.String s = '';";
    String content = """
import 'dart:core' as core;
blankLine() {
  $selection
  print(s);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/lib/core/core.dart');
    expect(elements.prefix, 'core');
    expect(elements.elements, unorderedEquals(['String']));
  }

  test_dartMath_noPrefix() async {
    String selection = "new Random();";
    String content = """
import 'dart:math';
bool randomBool() {
  Random r = $selection
  return r.nextBool();
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/lib/math/math.dart');
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['Random']));
  }

  test_multiple() async {
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
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(2));

    ImportedElements mathElements = elementsList[0];
    expect(mathElements, isNotNull);
    expect(mathElements.path, '/lib/math/math.dart');
    expect(mathElements.prefix, '');
    expect(mathElements.elements, unorderedEquals(['Random']));

    ImportedElements coreElements = elementsList[1];
    expect(coreElements, isNotNull);
    expect(coreElements.path, '/lib/core/core.dart');
    expect(coreElements.prefix, '');
    expect(coreElements.elements, unorderedEquals(['String', 'print']));
  }

  test_none_comment() async {
    String selection = 'comment';
    String content = """
// Method $selection.
blankLine() {
  print('');
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(0));
  }

  test_none_partialNames() async {
    String selection = 'x + y';
    String content = """
plusThree(int xx) {
  int yy = 2;
  print(x${selection}y);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(0));
  }

  test_none_wholeNames() async {
    String selection = 'x + y + 1';
    String content = """
plusThree(int x) {
  int y = 2;
  print($selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(0));
  }

  test_package_multipleInSame() async {
    addPackageSource('foo', 'foo.dart', '''
class A {
  static String a = '';
}
class B {
  static String b = '';
}
''');
    String selection = "A.a + B.b";
    String content = """
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/pubcache/foo/lib/foo.dart');
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['A', 'B']));
  }

  test_package_noPrefix() async {
    addPackageSource('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = "Foo.first";
    String content = """
import 'package:foo/foo.dart';
blankLine() {
  print($selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/pubcache/foo/lib/foo.dart');
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['Foo']));
  }

  test_package_prefix_selected() async {
    addPackageSource('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = "f.Foo.first";
    String content = """
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/pubcache/foo/lib/foo.dart');
    expect(elements.prefix, 'f');
    expect(elements.elements, unorderedEquals(['Foo']));
  }

  test_package_prefix_unselected() async {
    addPackageSource('foo', 'foo.dart', '''
class Foo {
  static String first = '';
}
''');
    String selection = "Foo.first";
    String content = """
import 'package:foo/foo.dart' as f;
blankLine() {
  print(f.$selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, '/pubcache/foo/lib/foo.dart');
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['Foo']));
  }

  test_package_prefixedAndNot() async {
    addPackageSource('foo', 'foo.dart', '''
class Foo {
  static String first = '';
  static String second = '';
}
''');
    String selection = "f.Foo.first + Foo.second";
    String content = """
import 'package:foo/foo.dart';
import 'package:foo/foo.dart' as f;
blankLine() {
  print($selection);
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);

    expect(elementsList, hasLength(2));
    ImportedElements elements1 = elementsList[0];
    ImportedElements elements2 = elementsList[1];
    ImportedElements notPrefixedElements;
    ImportedElements prefixedElements;
    if (elements1.prefix == '') {
      prefixedElements = elements2;
      notPrefixedElements = elements1;
    } else {
      prefixedElements = elements1;
      notPrefixedElements = elements2;
    }

    expect(notPrefixedElements, isNotNull);
    expect(notPrefixedElements.path, '/pubcache/foo/lib/foo.dart');
    expect(notPrefixedElements.prefix, '');
    expect(notPrefixedElements.elements, unorderedEquals(['Foo']));

    expect(prefixedElements, isNotNull);
    expect(prefixedElements.path, '/pubcache/foo/lib/foo.dart');
    expect(prefixedElements.prefix, 'f');
    expect(prefixedElements.elements, unorderedEquals(['Foo']));
  }

  test_self() async {
    String selection = 'A parent;';
    String content = """
class A {
  $selection
}
""";
    List<ImportedElements> elementsList = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elementsList, hasLength(1));
    ImportedElements elements = elementsList[0];
    expect(elements, isNotNull);
    expect(elements.path, sourcePath);
    expect(elements.prefix, '');
    expect(elements.elements, unorderedEquals(['A']));
  }

  Future<List<ImportedElements>> _computeElements(
      String sourceContent, int offset, int length) async {
    provider.newFile(sourcePath, sourceContent);
    ResolveResult result = await driver.getResult(sourcePath);
    ImportedElementsComputer computer =
        new ImportedElementsComputer(result.unit, offset, length);
    return computer.compute();
  }
}
