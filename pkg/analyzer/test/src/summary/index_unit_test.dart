// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(PackageIndexAssemblerTest);
}

class ExpectedLocation {
  final CompilationUnitElement unitElement;
  final int offset;
  final int length;
  final bool isQualified;
  final bool isResolved;

  ExpectedLocation(this.unitElement, this.offset, this.length, this.isQualified,
      this.isResolved);

  @override
  String toString() {
    return '(unit=$unitElement; offset=$offset; length=$length;'
        ' isQualified=$isQualified isResolved=$isResolved)';
  }
}

@reflectiveTest
class PackageIndexAssemblerTest extends AbstractSingleUnitTest {
  PackageIndex packageIndex;
  UnitIndex unitIndex;

  void test_isExtendedBy_ClassDeclaration() {
    _indexTestUnit('''
class A {} // 1
class B extends A {} // 2
''');
    ClassElement classElementA = findElement('A');
    // verify
    _assertHasRelation(classElementA, IndexRelationKind.IS_EXTENDED_BY,
        _expectedLocation('A {} // 2'));
  }

  void test_isReferencedBy_ClassElement() {
    _indexTestUnit('''
class A {
  static var field;
}
main(A p) {
  A v;
  new A(); // 2
  A.field = 1;
  print(A.field); // 3
}
''');
    ClassElement element = findElement("A");
    // verify
    _assertHasRelation(element, IndexRelationKind.IS_REFERENCED_BY,
        _expectedLocation('A p) {'));
    _assertHasRelation(
        element, IndexRelationKind.IS_REFERENCED_BY, _expectedLocation('A v;'));
    _assertHasRelation(element, IndexRelationKind.IS_REFERENCED_BY,
        _expectedLocation('A(); // 2'));
    _assertHasRelation(element, IndexRelationKind.IS_REFERENCED_BY,
        _expectedLocation('A.field = 1;'));
    _assertHasRelation(element, IndexRelationKind.IS_REFERENCED_BY,
        _expectedLocation('A.field); // 3'));
  }

  /**
   * Asserts that [unitIndex] has an item with the expected properties.
   */
  void _assertHasRelation(
      Element element,
      IndexRelationKind expectedRelationship,
      ExpectedLocation expectedLocation) {
    int elementId = _findElementId(element);
    for (int i = 0; i < unitIndex.locationOffsets.length; i++) {
      if (unitIndex.elements[i] == elementId &&
          unitIndex.locationOffsets[i] == expectedLocation.offset &&
          unitIndex.locationLengths[i] == expectedLocation.length) {
        return;
      }
    }
    _failWithIndexDump(
        'not found\n$element $expectedRelationship at $expectedLocation');
  }

  ExpectedLocation _expectedLocation(String search,
      {int length: -1, bool isQualified: false, bool isResolved: true}) {
    int offset = findOffset(search);
    if (length == -1) {
      length = getLeadingIdentifierLength(search);
    }
    return new ExpectedLocation(
        testUnitElement, offset, length, isQualified, isResolved);
  }

  void _failWithIndexDump(String msg) {
    String packageIndexJsonString =
        new JsonEncoder.withIndent('  ').convert(packageIndex.toJson());
    fail('$msg in\n' + packageIndexJsonString);
  }

  /**
   * Return the [element] identifier in [packageIndex] or fail.
   */
  int _findElementId(Element element) {
    int elementUnitId = _getElementUnitId(element);
    for (int elementId = 0;
        elementId < packageIndex.elementUnits.length;
        elementId++) {
      if (packageIndex.elementUnits[elementId] == elementUnitId &&
          packageIndex.elementOffsets[elementId] == element.nameOffset) {
        return elementId;
      }
    }
    _failWithIndexDump('Element $element is not referenced');
    return 0;
  }

  int _getElementUnitId(Element element) {
    CompilationUnitElement unitElement =
        PackageIndexAssembler.getUnitElement(element);
    int libraryUriId = _getUriId(unitElement.library.source.uri);
    int unitUriId = _getUriId(unitElement.library.source.uri);
    for (int i = 0; i < packageIndex.elementLibraryUris.length; i++) {
      if (packageIndex.elementLibraryUris[i] == libraryUriId &&
          packageIndex.elementUnitUris[i] == unitUriId) {
        return i;
      }
    }
    fail('Unit $unitElement of $element is not referenced in the index.');
    return -1;
  }

  int _getUriId(Uri uri) {
    String str = uri.toString();
    int id = packageIndex.uris.indexOf(str);
    expect(id, isNonNegative);
    return id;
  }

  void _indexTestUnit(String code) {
    resolveTestUnit(code);
    PackageIndexAssembler assembler = new PackageIndexAssembler();
    assembler.index(testUnit);
    // assemble, write and read
    PackageIndexBuilder indexBuilder = assembler.assemble();
    List<int> indexBytes = indexBuilder.toBuffer();
    packageIndex = new PackageIndex.fromBuffer(indexBytes);
    // prepare the only unit index
    expect(packageIndex.units, hasLength(1));
    unitIndex = packageIndex.units[0];
  }
}
