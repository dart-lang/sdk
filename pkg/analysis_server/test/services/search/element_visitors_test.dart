// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FindElementByNameOffsetTest);
  });
}

@reflectiveTest
class FindElementByNameOffsetTest extends AbstractSingleUnitTest {
  late TestCode code;

  late List<int> offsets = code.positions.map((p) => p.offset).toList();

  LibraryFragment get testUnitFragment => testUnit.declaredFragment!;

  @override
  Future<void> resolveTestCode(String content) {
    code = TestCode.parseNormalized(content);
    return super.resolveTestCode(code.code);
  }

  Future<void> test_class() async {
    await resolveTestCode(r'''
class /*0*/AAA {}
class /*1*/BBB {}
''');
    _assertElement(offsets[0], ElementKind.CLASS, 'AAA');
    _assertElement(offsets[1], ElementKind.CLASS, 'BBB');
  }

  Future<void> test_function() async {
    await resolveTestCode(r'''
void /*0*/aaa() {}
void /*1*/bbb() {}
''');
    _assertElement(offsets[0], ElementKind.FUNCTION, 'aaa');
    _assertElement(offsets[1], ElementKind.FUNCTION, 'bbb');
  }

  Future<void> test_null() async {
    await resolveTestCode(r'''
/*0*/c/*1*/lass/*2*/ A/*3*/AA {}
class BBB {}
''');

    expect(findFragmentByNameOffset(testUnitFragment, offsets[0]), isNull);
    expect(findFragmentByNameOffset(testUnitFragment, offsets[1]), isNull);

    expect(findFragmentByNameOffset(testUnitFragment, offsets[2]), isNull);
    expect(findFragmentByNameOffset(testUnitFragment, offsets[3]), isNull);
  }

  Future<void> test_topLevelVariable() async {
    await resolveTestCode(r'''
int? /*0*/aaa, /*1*/bbb;
int? /*2*/ccc;
''');
    _assertElement(offsets[0], ElementKind.TOP_LEVEL_VARIABLE, 'aaa');
    _assertElement(offsets[1], ElementKind.TOP_LEVEL_VARIABLE, 'bbb');
    _assertElement(offsets[2], ElementKind.TOP_LEVEL_VARIABLE, 'ccc');
  }

  void _assertElement(int nameOffset, ElementKind kind, String name) {
    var fragment = findFragmentByNameOffset(testUnitFragment, nameOffset)!;
    expect(fragment.element.kind, kind);
    expect(fragment.name, name);
  }
}
