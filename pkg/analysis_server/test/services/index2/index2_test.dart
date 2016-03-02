// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/index2/index2.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(Index2Test);
}

@reflectiveTest
class Index2Test extends AbstractSingleUnitTest {
  Index2 index = createMemoryIndex2();

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocation(List<Location> locations, String libraryUri,
      String unitUri, int offset, int length) {
    for (Location location in locations) {
      if (location.libraryUri == libraryUri &&
          location.unitUri == unitUri &&
          location.offset == offset &&
          location.length == length) {
        return location;
      }
    }
    fail('No at $offset with length $length in\n${locations.join('\n')}');
    return null;
  }

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocationSource(
      List<Location> locations, Source source, String search,
      {int length}) {
    String code = source.contents.data;
    int offset = code.indexOf(search);
    expect(offset, isNonNegative, reason: 'Not found "$search" in\n$code');
    length ??= getLeadingIdentifierLength(search);
    String uri = source.uri.toString();
    return findLocation(locations, uri, uri, offset, length);
  }

  /**
   * Return the [Location] with given properties, or fail.
   */
  Location findLocationTest(List<Location> locations, String search,
      {int length}) {
    int offset = findOffset(search);
    length ??= getLeadingIdentifierLength(search);
    String testUri = testSource.uri.toString();
    return findLocation(locations, testUri, testUri, offset, length);
  }

  void setUp() {
    super.setUp();
  }

  void tearDown() {
    super.tearDown();
    index = null;
  }

  test_getRelations_isExtendedBy() async {
    _indexTestUnit(r'''
class A {}
class B extends A {} // B
''');
    Source source2 = _indexUnit(
        '/test2.dart',
        r'''
import 'test.dart';
class C extends A {} // C
''');
    ClassElement elementA = testUnitElement.getType('A');
    List<Location> locations =
        await index.getRelations(elementA, IndexRelationKind.IS_EXTENDED_BY);
    findLocationTest(locations, 'A {} // B');
    findLocationSource(locations, source2, 'A {} // C');
  }

  test_getRelations_isReferencedBy() async {
    _indexTestUnit(r'''
main(int a, int b) {
}
''');
    ClassElement intElement = context.typeProvider.intType.element;
    List<Location> locations = await index.getRelations(
        intElement, IndexRelationKind.IS_REFERENCED_BY);
    findLocationTest(locations, 'int a');
    findLocationTest(locations, 'int b');
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(testUnit);
  }

  Source _indexUnit(String path, String code) {
    Source source = addSource(path, code);
    CompilationUnit unit = resolveLibraryUnit(source);
    index.indexUnit(unit);
    return source;
  }
}
