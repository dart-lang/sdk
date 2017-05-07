// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexTest);
  });
}

@reflectiveTest
class IndexTest extends AbstractSingleUnitTest {
  Index index = createMemoryIndex();

  @override
  bool get enableNewAnalysisDriver => false;

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocation(List<Location> locations, String libraryUri,
      String unitUri, int offset, int length, bool isQualified) {
    for (Location location in locations) {
      if (location.libraryUri == libraryUri &&
          location.unitUri == unitUri &&
          location.offset == offset &&
          location.length == length &&
          location.isQualified == isQualified) {
        return location;
      }
    }
    fail('No at $offset with length $length qualified=$isQualified in\n'
        '${locations.join('\n')}');
    return null;
  }

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocationSource(
      List<Location> locations, Source source, String search, bool isQualified,
      {int length}) {
    String code = source.contents.data;
    int offset = code.indexOf(search);
    expect(offset, isNonNegative, reason: 'Not found "$search" in\n$code');
    length ??= getLeadingIdentifierLength(search);
    String uri = source.uri.toString();
    return findLocation(locations, uri, uri, offset, length, isQualified);
  }

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocationTest(
      List<Location> locations, String search, bool isQualified,
      {int length}) {
    int offset = findOffset(search);
    length ??= getLeadingIdentifierLength(search);
    String testUri = testSource.uri.toString();
    return findLocation(
        locations, testUri, testUri, offset, length, isQualified);
  }

  void setUp() {
    super.setUp();
  }

  void tearDown() {
    super.tearDown();
    index = null;
  }

  test_getDefinedNames_classMember() async {
    await _indexTestUnit('''
class A {
  test() {}
}
class B {
  int test = 1;
  main() {
    int test = 2;
  }
}
''');
    ClassElement classA = findElement('A');
    ClassElement classB = findElement('B');
    List<Location> locations = await index.getDefinedNames(
        new RegExp(r'^test$'), IndexNameKind.classMember);
    expect(locations, hasLength(2));
    _assertHasDefinedName(locations, classA.methods[0]);
    _assertHasDefinedName(locations, classB.fields[0]);
  }

  test_getDefinedNames_topLevel() async {
    await _indexTestUnit('''
class A {} // A
class B = Object with A;
typedef C();
D() {}
var E = null;
class NoMatchABCDE {}
''');
    Element topA = findElement('A');
    Element topB = findElement('B');
    Element topC = findElement('C');
    Element topD = findElement('D');
    Element topE = findElement('E');
    List<Location> locations = await index.getDefinedNames(
        new RegExp(r'^[A-E]$'), IndexNameKind.topLevel);
    expect(locations, hasLength(5));
    _assertHasDefinedName(locations, topA);
    _assertHasDefinedName(locations, topB);
    _assertHasDefinedName(locations, topC);
    _assertHasDefinedName(locations, topD);
    _assertHasDefinedName(locations, topE);
  }

  test_getDefinedNames_topLevel2() async {
    await _indexTestUnit(
        '''
class A {} // A
class B = Object with A;
class NoMatchABCDE {}
''',
        declOnly: true);
    Element topA = findElement('A');
    Element topB = findElement('B');
    List<Location> locations = await index.getDefinedNames(
        new RegExp(r'^[A-E]$'), IndexNameKind.topLevel);
    expect(locations, hasLength(2));
    _assertHasDefinedName(locations, topA);
    _assertHasDefinedName(locations, topB);
  }

  test_getRelations_isExtendedBy() async {
    await _indexTestUnit(r'''
class A {}
class B extends A {} // B
''');
    Source source2 = await _indexUnit(
        '/test2.dart',
        r'''
import 'test.dart';
class C extends A {} // C
''');
    ClassElement elementA = testUnitElement.getType('A');
    List<Location> locations =
        await index.getRelations(elementA, IndexRelationKind.IS_EXTENDED_BY);
    findLocationTest(locations, 'A {} // B', false);
    findLocationSource(locations, source2, 'A {} // C', false);
  }

  test_getRelations_isReferencedBy() async {
    await _indexTestUnit(r'''
main(int a, int b) {
}
''');
    ClassElement intElement = context.typeProvider.intType.element;
    List<Location> locations = await index.getRelations(
        intElement, IndexRelationKind.IS_REFERENCED_BY);
    findLocationTest(locations, 'int a', false);
    findLocationTest(locations, 'int b', false);
  }

  test_getUnresolvedMemberReferences_qualified_resolved() async {
    await _indexTestUnit('''
class A {
  var test; // A
}
main(A a) {
  print(a.test);
  a.test = 1;
  a.test += 2;
  a.test();
}
''');
    List<Location> locations =
        await index.getUnresolvedMemberReferences('test');
    expect(locations, isEmpty);
  }

  test_getUnresolvedMemberReferences_qualified_unresolved() async {
    await _indexTestUnit('''
class A {
  var test; // A
}
main(p) {
  print(p.test);
  p.test = 1;
  p.test += 2;
  p.test();
  print(p.test2); // not requested
}
''');
    List<Location> locations =
        await index.getUnresolvedMemberReferences('test');
    expect(locations, hasLength(4));
    findLocationTest(locations, 'test);', true);
    findLocationTest(locations, 'test = 1;', true);
    findLocationTest(locations, 'test += 2;', true);
    findLocationTest(locations, 'test();', true);
  }

  test_getUnresolvedMemberReferences_unqualified_resolved() async {
    await _indexTestUnit('''
class A {
  var test;
  m() {
    print(test);
    test = 1;
    test += 2;
    test();
  }
}
''');
    List<Location> locations =
        await index.getUnresolvedMemberReferences('test');
    expect(locations, isEmpty);
  }

  test_getUnresolvedMemberReferences_unqualified_unresolved() async {
    verifyNoTestUnitErrors = false;
    await _indexTestUnit('''
class A {
  m() {
    print(test);
    test = 1;
    test += 2;
    test();
    print(test2); // not requested
  }
}
''');
    List<Location> locations =
        await index.getUnresolvedMemberReferences('test');
    expect(locations, hasLength(4));
    findLocationTest(locations, 'test);', false);
    findLocationTest(locations, 'test = 1;', false);
    findLocationTest(locations, 'test += 2;', false);
    findLocationTest(locations, 'test();', false);
  }

  test_indexDeclarations_afterIndexUnit() async {
    await resolveTestUnit('''
var a = 0;
var b = a + 1;
''');
    index.indexUnit(testUnit);
    TopLevelVariableElement a = findElement('a');
    // We can find references.
    {
      List<Location> locations = await index.getRelations(
          a.getter, IndexRelationKind.IS_REFERENCED_BY);
      findLocationTest(locations, 'a + 1', false);
    }
    // Attempt to index just declarations - we still can find references.
    index.indexDeclarations(testUnit);
    {
      List<Location> locations = await index.getRelations(
          a.getter, IndexRelationKind.IS_REFERENCED_BY);
      findLocationTest(locations, 'a + 1', false);
    }
  }

  test_indexDeclarations_nullUnit() async {
    index.indexDeclarations(null);
  }

  test_indexDeclarations_nullUnitElement() async {
    await resolveTestUnit('');
    testUnit.element = null;
    index.indexDeclarations(testUnit);
  }

  test_indexUnit_nullLibraryElement() async {
    await resolveTestUnit('');
    CompilationUnitElement unitElement = new _CompilationUnitElementMock();
    expect(unitElement.library, isNull);
    testUnit.element = unitElement;
    index.indexUnit(testUnit);
  }

  test_indexUnit_nullUnit() async {
    index.indexUnit(null);
  }

  test_indexUnit_nullUnitElement() async {
    await resolveTestUnit('');
    testUnit.element = null;
    index.indexUnit(testUnit);
  }

  test_removeContext() async {
    await _indexTestUnit('''
class A {}
''');
    RegExp regExp = new RegExp(r'^A$');
    expect(await index.getDefinedNames(regExp, IndexNameKind.topLevel),
        hasLength(1));
    // remove the context - no top-level declarations
    index.removeContext(context);
    expect(
        await index.getDefinedNames(regExp, IndexNameKind.topLevel), isEmpty);
  }

  test_removeUnit() async {
    RegExp regExp = new RegExp(r'^[AB]$');
    Source sourceA = addSource('/a.dart', 'class A {}');
    Source sourceB = addSource('/b.dart', 'class B {}');
    CompilationUnit unitA = await resolveLibraryUnit(sourceA);
    CompilationUnit unitB = await resolveLibraryUnit(sourceB);
    index.indexUnit(unitA);
    index.indexUnit(unitB);
    {
      List<Location> locations =
          await index.getDefinedNames(regExp, IndexNameKind.topLevel);
      expect(locations, hasLength(2));
      expect(locations.map((l) => l.libraryUri),
          unorderedEquals([sourceA.uri.toString(), sourceB.uri.toString()]));
    }
    // remove a.dart - no a.dart location
    index.removeUnit(context, sourceA, sourceA);
    {
      List<Location> locations =
          await index.getDefinedNames(regExp, IndexNameKind.topLevel);
      expect(locations, hasLength(1));
      expect(locations.map((l) => l.libraryUri),
          unorderedEquals([sourceB.uri.toString()]));
    }
  }

  /**
   * Assert that the given list of [locations] has a [Location] corresponding
   * to the [element].
   */
  void _assertHasDefinedName(List<Location> locations, Element element) {
    String libraryUri = element.library.source.uri.toString();
    String unitUri = element.source.uri.toString();
    for (Location location in locations) {
      if (location.libraryUri == libraryUri &&
          location.unitUri == unitUri &&
          location.offset == element.nameOffset &&
          location.length == element.nameLength) {
        return;
      }
    }
    fail('No declaration of $element at ${element.nameOffset} in\n'
        '${locations.join('\n')}');
  }

  Future<Null> _indexTestUnit(String code, {bool declOnly: false}) async {
    await resolveTestUnit(code);
    if (declOnly) {
      index.indexDeclarations(testUnit);
    } else {
      index.indexUnit(testUnit);
    }
  }

  Future<Source> _indexUnit(String path, String code) async {
    Source source = addSource(path, code);
    CompilationUnit unit = await resolveLibraryUnit(source);
    index.indexUnit(unit);
    return source;
  }
}

class _CompilationUnitElementMock extends TypedMock
    implements CompilationUnitElement {}
