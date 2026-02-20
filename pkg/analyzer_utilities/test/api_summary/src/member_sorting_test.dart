// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_utilities/src/api_summary/src/extensions.dart';
import 'package:analyzer_utilities/src/api_summary/src/member_sorting.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberTest);
  });
}

@reflectiveTest
class MemberTest extends ApiSummaryTest {
  Future<void> test_sortOrder_member_categoryBeforeName() async {
    _checkSorting(
      elements: (await analyzeLibrary('''
class C {
  C.a1();
  get a2 => 0;
  a3() {}
  C.z1();
  get z2 => 0;
  z3() {}
  }
''')).getClass('C')!.childrenExcludingPropertyInducingElements,
      expectedOrder: ['a1', 'z1', 'a2', 'z2', 'a3', 'z3'],
    );
  }

  Future<void> test_sortOrder_member_staticBeforeInstance() async {
    _checkSorting(
      elements: (await analyzeLibrary('''
class C {
  C.a1();
  C.z1();
  get a2 => 0;
  get z2 => 0;
  static get a3 => 0;
  static get z3 => 0;
  a4() {}
  z4() {}
  static a5() {}
  static z5() {}
}
''')).getClass('C')!.childrenExcludingPropertyInducingElements,
      expectedOrder: [
        'a3',
        'z3',
        'a5',
        'z5',
        'a1',
        'z1',
        'a2',
        'z2',
        'a4',
        'z4',
      ],
    );
  }

  Future<void> test_sortOrder_topLevel_categoryBeforeName() async {
    _checkSorting(
      elements: (await analyzeLibrary('''
get a1 => 0;
a2() {}
class a3 {}
extension a4 on int {}
typedef a5 = int;
get z1 => 0;
z2() {}
class z3 {}
extension z4 on int {}
typedef z5 = int;
''')).childrenExcludingPropertyInducingElements,
      expectedOrder: [
        'a1',
        'z1',
        'a2',
        'z2',
        'a3',
        'z3',
        'a4',
        'z4',
        'a5',
        'z5',
      ],
    );
  }

  Future<void> test_sortOrder_topLevel_interfaceTypesTogether() async {
    _checkSorting(
      elements: (await analyzeLibrary('''
class A1 {}
class Z1 {}
mixin A2 {}
mixin Z2 {}
enum A3 { v }
enum Z3 { v }
extension type A4(int i) {}
extension type Z4(int i) {}
''')).childrenExcludingPropertyInducingElements,
      expectedOrder: ['A1', 'A2', 'A3', 'A4', 'Z1', 'Z2', 'Z3', 'Z4'],
    );
  }

  Future<void> test_sortOrder_topLevel_oldAndNewTypedefsTogether() async {
    _checkSorting(
      elements: (await analyzeLibrary('''
typedef void A1();
typedef void Z1();
typedef A2 = void Function();
typedef Z2 = void Function();
typedef A3 = int;
typedef Z3 = int;
''')).childrenExcludingPropertyInducingElements,
      expectedOrder: ['A1', 'A2', 'A3', 'Z1', 'Z2', 'Z3'],
    );
  }

  void _checkSorting({
    required List<Element> elements,
    required List<String> expectedOrder,
  }) {
    expect(
      elements.sortedBy((e) => MemberSortKey(e)).map((e) => e.apiName).toList(),
      expectedOrder,
    );
    expect(
      elements.reversed
          .sortedBy((e) => MemberSortKey(e))
          .map((e) => e.apiName)
          .toList(),
      expectedOrder,
    );
  }
}

extension on Element {
  /// All children of `this` excluding [PropertyInducingElement]s.
  ///
  /// This is used for testing the sort order of class members, since the API
  /// summary only considers getters and setters; it ignores the fields and top
  /// level variables that induce them.
  List<Element> get childrenExcludingPropertyInducingElements =>
      children.whereNot((e) => e is PropertyInducingElement).toList();
}
