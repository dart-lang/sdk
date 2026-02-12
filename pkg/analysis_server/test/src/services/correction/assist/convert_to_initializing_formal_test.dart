// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToInitializingFormalLocationTest);
    defineReflectiveTests(ConvertToInitializingFormalRenameTest);
    defineReflectiveTests(ConvertToInitializingFormalDifferentTypesTest);
    defineReflectiveTests(ConvertToInitializingFormalPrivateTest);
    defineReflectiveTests(ConvertToInitializingFormalOtherTest);
  });
}

/// Test that if the parameter and field have different types then the parameter
/// type is retained.
@reflectiveTest
class ConvertToInitializingFormalDifferentTypesTest
    extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInitializingFormal;

  Future<void> test_assignment() async {
    await resolveTestCode('''
class C {
  Object a = '';
  C(String ^a) {
    this.a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  Object a = '';
  C(String this.a);
}
''');
  }

  Future<void> test_initializer() async {
    await resolveTestCode('''
class C {
  Object a = '';
  C(String ^a) : a = a;
}
''');
    await assertHasAssist('''
class C {
  Object a = '';
  C(String this.a);
}
''');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class C {
  Object? a;
  C({String? ^a}) {
    this.a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  Object? a;
  C({String? this.a});
}
''');
  }

  Future<void> test_optionalPositional() async {
    await resolveTestCode('''
class C {
  Object? a;
  C([String? ^a]) {
    this.a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  Object? a;
  C([String? this.a]);
}
''');
  }
}

/// Tests where the cursor can and can't be while triggering the assist.
@reflectiveTest
class ConvertToInitializingFormalLocationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInitializingFormal;

  Future<void> test_assignment_leftSide() async {
    // This would be useful to support, but isn't currently handled.
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? aaa) {
    this.^aaa = aaa;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_assignment_rightSide() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? aaa) {
    this.aaa = ^aaa;
  }
}
''');
    await assertHasAssist('''
class A {
  int? aaa;
  A(this.aaa);
}
''');
  }

  Future<void> test_fieldDeclaration() async {
    // This would be useful to support, but isn't currently handled.
    await resolveTestCode('''
class A {
  int? ^test;
  A(int? test) : test = test;
}
''');
    await assertNoAssist();
  }

  Future<void> test_initializer_leftSide() async {
    // This would be useful to support, but isn't currently handled.
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? aaa) : ^aaa = aaa;
}
''');
    await assertNoAssist();
  }

  Future<void> test_initializer_rightSide() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? aaa) : aaa = ^aaa;
}
''');
    await assertHasAssist('''
class A {
  int? aaa;
  A(this.aaa);
}
''');
  }

  Future<void> test_initializer_rightSide_explicitThis() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? aaa) : this.aaa = ^aaa;
}
''');
    await assertHasAssist('''
class A {
  int? aaa;
  A(this.aaa);
}
''');
  }

  Future<void> test_parameterDeclaration() async {
    await resolveTestCode('''
class A {
  int test;
  A(int ^test) : test = test;
}
''');
    await assertHasAssist('''
class A {
  int test;
  A(this.test);
}
''');
  }
}

@reflectiveTest
class ConvertToInitializingFormalOtherTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInitializingFormal;

  Future<void> test_assignment_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int ^a) {
    this.a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  int a = 0;
  C(this.a);
}
''');
  }

  Future<void> test_assignment_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int ^a) {
    this.a = a;
    print(1);
  }
}
''');
    await assertHasAssist('''
class C {
  int a = 0;
  C(this.a) {
    print(1);
  }
}
''');
  }

  Future<void> test_assignment_notSimple() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A(int? ^aaa) {
    this.aaa = aaa ?? 2;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_bothInitializerAndAssignment() async {
    await resolveTestCode('''
class A {
  int aaa;
  A(int ^aaa) : aaa = aaa {
    this.aaa = aaa;
  }
}
''');
    await assertHasAssist('''
class A {
  int aaa;
  A(this.aaa) {
    this.aaa = aaa;
  }
}
''');
  }

  Future<void> test_initializer_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  C(int ^a) : this.a = a;
}
''');
    await assertHasAssist('''
class C {
  int a;
  C(this.a);
}
''');
  }

  Future<void> test_initializer_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  int b;
  C(int ^a) : this.a = a, this.b = 2;
}
''');
    await assertHasAssist('''
class C {
  int a;
  int b;
  C(this.a) : this.b = 2;
}
''');
  }

  Future<void> test_initializer_notSimple() async {
    await resolveTestCode('''
class A {
  int aaa;
  A(int ^aaa) : aaa = aaa * 2;
}
''');
    await assertNoAssist();
  }

  Future<void> test_multipleInitializers_first() async {
    await resolveTestCode('''
class A {
  int aaa2;
  int bbb2;
  A(int ^aaa, int bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssist('''
class A {
  int aaa2;
  int bbb2;
  A(this.aaa2, int bbb) : bbb2 = bbb;
}
''');
  }

  Future<void> test_multipleInitializers_second() async {
    await resolveTestCode('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa, int ^bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssist('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa, this.bbb2) : aaa2 = aaa;
}
''');
  }

  Future<void> test_multipleUses() async {
    await resolveTestCode('''
class A {
  int aaa;
  A(int ^aaa) : aaa = aaa {
    print(aaa + aaa + aaa);
  }
}
''');
    await assertHasAssist('''
class A {
  int aaa;
  A(this.aaa) {
    print(aaa + aaa + aaa);
  }
}
''');
  }

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A({int? aaa}) : aaa = ^aaa;
}
''');
    await assertHasAssist('''
class A {
  int? aaa;
  A({this.aaa});
}
''');
  }

  Future<void> test_optionalParameter() async {
    await resolveTestCode('''
class A {
  int? aaa;
  A([int? aaa]) : aaa = ^aaa;
}
''');
    await assertHasAssist('''
class A {
  int? aaa;
  A([this.aaa]);
}
''');
  }

  Future<void> test_requiredNamed() async {
    await resolveTestCode('''
class C {
  final int foo;
  C({required int ^foo}) : foo = foo;
}
''');
    await assertHasAssist('''
class C {
  final int foo;
  C({required this.foo});
}
''');
  }
}

/// Tests how privacy interacts with the assist.
@reflectiveTest
class ConvertToInitializingFormalPrivateTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInitializingFormal;

  Future<void> test_named_differentTypes() async {
    await resolveTestCode('''
class C {
  num? _a;
  C({int? ^a = 1}) {
    this._a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  num? _a;
  C({int? this._a = 1});
}
''');
  }

  Future<void> test_named_inAssignment() async {
    await resolveTestCode('''
class C {
  int? _a;
  C({int? ^a = 1}) {
    this._a = a;
  }
}
''');
    await assertHasAssist('''
class C {
  int? _a;
  C({this._a = 1});
}
''');
  }

  Future<void> test_named_inInitializer() async {
    await resolveTestCode('''
class C {
  Object? _a;
  C({Object? ^a}) : _a = a;
}
''');
    await assertHasAssist('''
class C {
  Object? _a;
  C({this._a});
}
''');
  }

  Future<void> test_named_unsupported() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  int? _a;
  C({int? ^a = 1}) {
    this._a = a;
  }
}
''');
    await assertNoAssist();
  }
}

/// Tests when the assist can and can't apply if the field and parameter names
/// aren't the same.
@reflectiveTest
class ConvertToInitializingFormalRenameTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToInitializingFormal;

  Future<void> test_namedParameter_assignment() async {
    await resolveTestCode('''
class A {
  int? field;
  A({int? ^param}) {
    this.field = param;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_namedParameter_initializer() async {
    await resolveTestCode('''
class A {
  int? field;
  A({int? ^param}) : field = param;
}
''');
    await assertNoAssist();
  }

  Future<void> test_optionalParameter_assignment() async {
    await resolveTestCode('''
class A {
  int? field;
  A([int? ^param]) {
    this.field = param;
  }
}
''');
    await assertHasAssist('''
class A {
  int? field;
  A([this.field]);
}
''');
  }

  Future<void> test_optionalParameter_initializer() async {
    await resolveTestCode('''
class A {
  int? field;
  A([int? ^param]) : field = param;
}
''');
    await assertHasAssist('''
class A {
  int? field;
  A([this.field]);
}
''');
  }

  Future<void> test_positionalParameter_assignment() async {
    await resolveTestCode('''
class A {
  int? field;
  A(int? ^param) {
    this.field = param;
  }
}
''');
    await assertHasAssist('''
class A {
  int? field;
  A(this.field);
}
''');
  }

  Future<void> test_positionalParameter_initializer() async {
    await resolveTestCode('''
class A {
  int? field;
  A(int? ^param) : field = param;
}
''');
    await assertHasAssist('''
class A {
  int? field;
  A(this.field);
}
''');
  }
}
