// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObjectPatternTest);
  });
}

@reflectiveTest
class ObjectPatternTest extends AbstractCompletionDriverTest
    with ObjectPatternTestCases {
  @override
  Future<void> setUp() async {
    await super.setUp();
    printerConfiguration.withLocationName = true;
  }
}

mixin ObjectPatternTestCases on AbstractCompletionDriverTest {
  Future<void>
  test_declarationContext_pattern_first_withoutGetter_afterColon() async {
    await computeSuggestions('''
void f1(A1 x0) {
  var A1(: ^) = x0;
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
suggestions
  f01
    kind: field
  f11
    kind: field
  final
    kind: keyword
  g01
    kind: getter
  g11
    kind: getter
  var
    kind: keyword
''');
  }

  Future<void>
  test_declarationContext_pattern_first_withoutGetter_afterColon_partial() async {
    await computeSuggestions('''
void f1(A1 x0) {
  var A1(: g^) = x0;
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
replacement
  left: 1
suggestions
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void>
  test_forEachPartsWithPattern_first_afterColon_withoutGetter() async {
    await computeSuggestions('''
void f1(List<A1> x0) {
  for (final A1(: ^) in x0) {}
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
suggestions
  f01
    kind: field
  f11
    kind: field
  final
    kind: keyword
  g01
    kind: getter
  g11
    kind: getter
  var
    kind: keyword
''');
  }

  Future<void>
  test_forEachPartsWithPattern_first_afterColon_withoutGetter_partial() async {
    await computeSuggestions('''
void f1(List<A1> x0) {
  for (final A1(: g^) in x0) {}
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
replacement
  left: 1
suggestions
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_forEachPartsWithPattern_first_beforeColon() async {
    await computeSuggestions('''
void f1(List<A1> x0) {
  for (final A1(^:) in x0) {}
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
suggestions
  f01
    kind: field
  f11
    kind: field
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_forEachPartsWithPattern_first_beforeColon_partial() async {
    await computeSuggestions('''
void f1(List<A1> x0) {
  for (final A1(g^:) in x0) {}
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
replacement
  left: 1
suggestions
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_ifCase_logicalAnd_objectPattern_type_partial() async {
    await computeSuggestions('''
class A01 {}

void f(Object? x) {
  if (x case true && A0^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void>
  test_ifCase_logicalAnd_objectPattern_type_partial_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
''');

    await computeSuggestions('''
void f(Object? x) {
  if (x case true && A0^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_logicalAnd_recordPattern() async {
    await computeSuggestions('''
class A01 {}

void f(Object? x) {
  if (x case true && ^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_logicalAnd_recordPattern_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
''');

    await computeSuggestions('''
void f(Object? x) {
  if (x case true && ^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_objectPattern_type_partial() async {
    await computeSuggestions('''
class A01 {}

void f(Object? x) {
  if (x case A0^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_objectPattern_type_partial_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
''');

    await computeSuggestions('''
void f(Object? x) {
  if (x case A0^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_recordPattern() async {
    await computeSuggestions('''
class A01 {}

void f(Object? x) {
  if (x case ^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
suggestions
  A01
    kind: class
''');
  }

  Future<void> test_ifCase_recordPattern_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
''');

    await computeSuggestions('''
void f(Object? x) {
  if (x case ^()) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
suggestions
  A01
    kind: class
''');
  }

  Future<void>
  test_matchingContext_pattern_first_withoutGetter_afterColon() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(: ^)
  }
}
class A1 {
  int f01 = 0;
  int get g01 => 0;
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
suggestions
  f01
    kind: field
  final
    kind: keyword
  g01
    kind: getter
  var
    kind: keyword
''');
  }

  Future<void>
  test_matchingContext_pattern_first_withoutGetter_afterVar() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(: var ^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: PatternField_pattern
locationOpType: PatternField_pattern
suggestions
  f01
    kind: field
  f11
    kind: field
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  @FailingTest(reason: 'Suggest invalid static field / getter')
  Future<void> test_pattern_first() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(f01: ^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  A1
    kind: class
  A1
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
  x0
    kind: parameter
''');
  }

  @FailingTest(reason: 'Suggest invalid static field / getter')
  Future<void> test_pattern_second() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(f01: < 3, g01: ^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  A1
    kind: class
  A1
    kind: constructorInvocation
  const
    kind: keyword
  false
    kind: keyword
  final
    kind: keyword
  null
    kind: keyword
  true
    kind: keyword
  var
    kind: keyword
  x0
    kind: parameter
''');
  }

  Future<void> test_property_first() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() {}
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() {}
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
suggestions
  f01
    kind: field
  f11
    kind: field
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_property_first_afterPartialName() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(f^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
replacement
  left: 1
suggestions
  f01
    kind: field
  f11
    kind: field
''');
  }

  Future<void>
  test_property_first_afterPartialName_trailingColonAndValue() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(f^: var a)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
replacement
  left: 1
suggestions
  f01
    kind: field
  f11
    kind: field
''');
  }

  Future<void>
  test_property_first_beforePartialName_trailingColonAndValue() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(^f: var a)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
replacement
  right: 1
suggestions
  f01
    kind: field
  f11
    kind: field
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_property_second() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(f01: < 3, ^)
  }
}
class A0 {
  int f01 = 0;
  int get g01 => 0;
  set s01(x) {}
  int m01() => 0;
  static int f02 = 0;
  static int get g02 => 0;
  static int m02() => 0;
  static set s02(x) {}
}
class A1 extends A0 {
  int f11 = 0;
  int get g11 => 0;
  set s11(x) {}
  int m11() => 0;
  static int f12 = 0;
  static int get g12 => 0;
  static int m12() => 0;
  static set s12(x) {}
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
suggestions
  f11
    kind: field
  g01
    kind: getter
  g11
    kind: getter
''');
  }

  Future<void> test_property_second_implicitFirst() async {
    await computeSuggestions('''
void f1(Object x0) {
  switch (x0) {
    case A1(:var f01, ^)
  }
}
class A0 {
  int f01 = 0;
  int f02 = 0;
}
class A1 extends A0 {
  int f11 = 0;
}
''');
    assertResponse(r'''
location: ObjectPattern_fieldName
locationOpType: ObjectPattern_fieldName
suggestions
  f02
    kind: field
  f11
    kind: field
''');
  }

  Future<void> test_switchPatternCase_objectPattern_type_partial() async {
    await computeSuggestions('''
class A01 {}

void f(Object? x) {
  switch (x) {
    case A0^():
  }
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }

  Future<void>
  test_switchPatternCase_objectPattern_type_partial_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A01 {}
''');

    await computeSuggestions('''
void f(Object? x) {
  switch (x) {
    case A0^():
  }
}
''');
    assertResponse(r'''
location: ObjectPattern_type
locationOpType: ObjectPattern_type
replacement
  left: 2
suggestions
  A01
    kind: class
''');
  }
}
