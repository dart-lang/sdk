// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analyzer/dart/element/element.dart';
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
  LibraryFragment get testUnitFragment => testUnit.declaredFragment!;

  @override
  void setUp() {
    useLineEndingsForPlatform = false;
    super.setUp();
  }

  Future<void> test_class() async {
    await resolveTestCode(r'''
class AAA {}
class BBB {}
''');
    _assertElement(6, ElementKind.CLASS, 'AAA');
    _assertElement(19, ElementKind.CLASS, 'BBB');
  }

  Future<void> test_function() async {
    await resolveTestCode(r'''
void aaa() {}
void bbb() {}
''');
    _assertElement(5, ElementKind.FUNCTION, 'aaa');
    _assertElement(19, ElementKind.FUNCTION, 'bbb');
  }

  Future<void> test_null() async {
    await resolveTestCode(r'''
class AAA {}
class BBB {}
''');

    expect(findFragmentByNameOffset(testUnitFragment, 0), isNull);
    expect(findFragmentByNameOffset(testUnitFragment, 1), isNull);

    expect(findFragmentByNameOffset(testUnitFragment, 5), isNull);
    expect(findFragmentByNameOffset(testUnitFragment, 7), isNull);
  }

  Future<void> test_topLevelVariable() async {
    await resolveTestCode(r'''
int? aaa, bbb;
int? ccc;
''');
    _assertElement(5, ElementKind.TOP_LEVEL_VARIABLE, 'aaa');
    _assertElement(10, ElementKind.TOP_LEVEL_VARIABLE, 'bbb');
    _assertElement(20, ElementKind.TOP_LEVEL_VARIABLE, 'ccc');
  }

  void _assertElement(int nameOffset, ElementKind kind, String name) {
    var fragment = findFragmentByNameOffset(testUnitFragment, nameOffset)!;
    expect(fragment.element.kind, kind);
    expect(fragment.name, name);
  }
}
