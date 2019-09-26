// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableTest);
    defineReflectiveTests(NullableTest);
  });
}

@reflectiveTest
class NonNullableTest extends DriverResolutionTest {
  // TODO(danrubel): Implement a more fine grained way to specify non-nullable.
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  @override
  bool get typeToStringWithNullability => true;

  test_class_hierarchy() async {
    await resolveTestCode('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A');
    assertType(findNode.typeName('A {} // 2'), 'A');
    assertType(findNode.typeName('A {} // 3'), 'A');
  }

  test_classTypeAlias_hierarchy() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A with'), 'A');
    assertType(findNode.typeName('B implements'), 'B');
    assertType(findNode.typeName('C;'), 'C');
  }

  test_local_getterNullAwareAccess_interfaceType() async {
    await resolveTestCode(r'''
main() {
  int? x;
  return x?.isEven;
}
''');

    assertNoTestErrors();
    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_local_interfaceType() async {
    await resolveTestCode('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_local_interfaceType_generic() async {
    await resolveTestCode('''
main() {
  List<int?>? a = [];
  List<int>? b = [];
  List<int?> c = [];
  List<int> d = [];
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('List<int?>? a'), 'List<int?>?');
    assertType(findNode.typeName('List<int>? b'), 'List<int>?');
    assertType(findNode.typeName('List<int?> c'), 'List<int?>');
    assertType(findNode.typeName('List<int> d'), 'List<int>');
  }

  test_local_methodNullAwareCall_interfaceType() async {
    await resolveTestCode(r'''
class C {
  bool x() => true;
}

main() {
  C? c;
  return c?.x();
}
''');

    assertNoTestErrors();
    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_local_nullCoalesce_nullableInt_int() async {
    await resolveTestCode(r'''
main() {
  int? x;
  int y = 0;
  x ?? y;
}
''');
    assertNoTestErrors();
    assertType(findNode.binary('x ?? y'), 'int');
  }

  test_local_nullCoalesce_nullableInt_nullableInt() async {
    await resolveTestCode(r'''
main() {
  int? x;
  x ?? x;
}
''');
    assertNoTestErrors();
    assertType(findNode.binary('x ?? x'), 'int?');
  }

  test_local_nullCoalesceAssign_nullableInt_int() async {
    await resolveTestCode(r'''
main() {
  int? x;
  int y = 0;
  x ??= y;
}
''');
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_local_nullCoalesceAssign_nullableInt_nullableInt() async {
    await resolveTestCode(r'''
main() {
  int? x;
  x ??= x;
}
''');
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_local_typeParameter() async {
    await resolveTestCode('''
main<T>(T a) {
  T x = a;
  T? y;
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('T x'), 'T');
    assertType(findNode.typeName('T? y'), 'T?');
  }

  @failingTest
  test_local_variable_genericFunctionType() async {
    await resolveTestCode('''
main() {
  int? Function(bool, String?)? a;
}
''');
    assertNoTestErrors();

    assertType(
      findNode.genericFunctionType('Function('),
      '(bool!, String?) → int??',
    );
  }

  test_localFunction_parameter_interfaceType() async {
    await resolveTestCode('''
main() {
  f(int? a, int b) {}
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_localFunction_returnType_interfaceType() async {
    await resolveTestCode('''
main() {
  int? f() => 0;
  int g() => 0;
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('int? f'), 'int?');
    assertType(findNode.typeName('int g'), 'int');
  }

  test_member_potentiallyNullable_called() async {
    await resolveTestCode(r'''
m<T extends Function>() {
  List<T?> x;
  x.first();
}
''');
// Do not assert no test errors. Deliberately invokes nullable type.
    assertType(findNode.methodInvocation('first').methodName, 'Function?');
  }

  test_mixin_hierarchy() async {
    await resolveTestCode('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A');
    assertType(findNode.typeName('A {} // 2'), 'A');
  }

  test_null_assertion_operator_changes_null_to_never() async {
    await resolveTestCode('''
main() {
  Null x = null;
  x!;
}
''');
    assertNoTestErrors();
    assertType(findNode.postfix('x!'), 'Never');
  }

  test_null_assertion_operator_removes_nullability() async {
    await resolveTestCode('''
main() {
  Object? x = null;
  x!;
}
''');
    assertNoTestErrors();
    assertType(findNode.postfix('x!'), 'Object');
  }

  @failingTest
  test_parameter_genericFunctionType() async {
    await resolveTestCode('''
main(int? Function(bool, String?)? a) {
}
''');
    assertNoTestErrors();

    assertType(
      findNode.genericFunctionType('Function('),
      '(bool!, String?) → int??',
    );
  }

  test_parameter_getterNullAwareAccess_interfaceType() async {
    await resolveTestCode(r'''
main(int? x) {
  return x?.isEven;
}
''');

    assertNoTestErrors();
    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_parameter_interfaceType() async {
    await resolveTestCode('''
main(int? a, int b) {
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_parameter_interfaceType_generic() async {
    await resolveTestCode('''
main(List<int?>? a, List<int>? b, List<int?> c, List<int> d) {
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('List<int?>? a'), 'List<int?>?');
    assertType(findNode.typeName('List<int>? b'), 'List<int>?');
    assertType(findNode.typeName('List<int?> c'), 'List<int?>');
    assertType(findNode.typeName('List<int> d'), 'List<int>');
  }

  test_parameter_methodNullAwareCall_interfaceType() async {
    await resolveTestCode(r'''
class C {
  bool x() => true;
}

main(C? c) {
  return c?.x();
}
''');

    assertNoTestErrors();
    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_parameter_nullCoalesce_nullableInt_int() async {
    await resolveTestCode(r'''
main(int? x, int y) {
  x ?? y;
}
''');
    assertNoTestErrors();
    assertType(findNode.binary('x ?? y'), 'int');
  }

  test_parameter_nullCoalesce_nullableInt_nullableInt() async {
    await resolveTestCode(r'''
main(int? x) {
  x ?? x;
}
''');
    assertNoTestErrors();
    assertType(findNode.binary('x ?? x'), 'int?');
  }

  test_parameter_nullCoalesceAssign_nullableInt_int() async {
    await resolveTestCode(r'''
main(int? x, int y) {
  x ??= y;
}
''');
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_parameter_nullCoalesceAssign_nullableInt_nullableInt() async {
    await resolveTestCode(r'''
main(int? x) {
  x ??= x;
}
''');
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_parameter_typeParameter() async {
    await resolveTestCode('''
main<T>(T a, T? b) {
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('T a'), 'T');
    assertType(findNode.typeName('T? b'), 'T?');
  }

  test_typedef_classic() async {
    await resolveTestCode('''
typedef int? F(bool a, String? b);

main() {
  F? a;
}
''');
    assertNoTestErrors();

    assertType(findNode.typeName('F? a'), 'int? Function(bool, String?)?');
  }

  @failingTest
  test_typedef_function() async {
    await resolveTestCode('''
typedef F<T> = int? Function(bool, T, T?);

main() {
  F<String>? a;
}
''');
    assertNoTestErrors();

    assertType(
      findNode.typeName('F<String>'),
      'int? Function(bool!, String!, String?)?',
    );
  }
}

@reflectiveTest
class NullableTest extends DriverResolutionTest {
  @override
  bool get typeToStringWithNullability => true;

  test_class_hierarchy() async {
    await resolveTestCode('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A*');
    assertType(findNode.typeName('A {} // 2'), 'A*');
    assertType(findNode.typeName('A {} // 3'), 'A*');
  }

  test_classTypeAlias_hierarchy() async {
    await resolveTestCode('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A with'), 'A*');
    assertType(findNode.typeName('B implements'), 'B*');
    assertType(findNode.typeName('C;'), 'C*');
  }

  test_local_variable_interfaceType_notMigrated() async {
    await resolveTestCode('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    assertTestErrorsWithCodes([ParserErrorCode.EXPERIMENT_NOT_ENABLED]);

    assertType(findNode.typeName('int? a'), 'int*');
    assertType(findNode.typeName('int b'), 'int*');
  }

  test_mixin_hierarchy() async {
    await resolveTestCode('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A*');
    assertType(findNode.typeName('A {} // 2'), 'A*');
  }
}
