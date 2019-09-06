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
    addTestFile('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A');
    assertType(findNode.typeName('A {} // 2'), 'A');
    assertType(findNode.typeName('A {} // 3'), 'A');
  }

  test_classTypeAlias_hierarchy() async {
    addTestFile('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A with'), 'A');
    assertType(findNode.typeName('B implements'), 'B');
    assertType(findNode.typeName('C;'), 'C');
  }

  test_local_getterNullAwareAccess_interfaceType() async {
    addTestFile(r'''
main() {
  int? x;
  return x?.isEven;
}
''');

    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_local_interfaceType() async {
    addTestFile('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_local_interfaceType_generic() async {
    addTestFile('''
main() {
  List<int?>? a = [];
  List<int>? b = [];
  List<int?> c = [];
  List<int> d = [];
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('List<int?>? a'), 'List<int?>?');
    assertType(findNode.typeName('List<int>? b'), 'List<int>?');
    assertType(findNode.typeName('List<int?> c'), 'List<int?>');
    assertType(findNode.typeName('List<int> d'), 'List<int>');
  }

  test_local_methodNullAwareCall_interfaceType() async {
    await addTestFile(r'''
class C {
  bool x() => true;
}

main() {
  C? c;
  return c?.x();
}
''');

    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_local_nullCoalesce_nullableInt_int() async {
    await addTestFile(r'''
main() {
  int? x;
  int y = 0;
  x ?? y;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.binary('x ?? y'), 'int');
  }

  test_local_nullCoalesce_nullableInt_nullableInt() async {
    await addTestFile(r'''
main() {
  int? x;
  x ?? x;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.binary('x ?? x'), 'int?');
  }

  test_local_nullCoalesceAssign_nullableInt_int() async {
    await addTestFile(r'''
main() {
  int? x;
  int y = 0;
  x ??= y;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_local_nullCoalesceAssign_nullableInt_nullableInt() async {
    await addTestFile(r'''
main() {
  int? x;
  x ??= x;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_local_typeParameter() async {
    addTestFile('''
main<T>(T a) {
  T x = a;
  T? y;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('T x'), 'T');
    assertType(findNode.typeName('T? y'), 'T?');
  }

  @failingTest
  test_local_variable_genericFunctionType() async {
    addTestFile('''
main() {
  int? Function(bool, String?)? a;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(
      findNode.genericFunctionType('Function('),
      '(bool!, String?) → int??',
    );
  }

  test_localFunction_parameter_interfaceType() async {
    addTestFile('''
main() {
  f(int? a, int b) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_localFunction_returnType_interfaceType() async {
    addTestFile('''
main() {
  int? f() => 0;
  int g() => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? f'), 'int?');
    assertType(findNode.typeName('int g'), 'int');
  }

  test_member_potentiallyNullable_called() async {
    addTestFile(r'''
m<T extends Function>() {
  List<T?> x;
  x.first();
}
''');
    await resolveTestFile();
    // Do not assert no test errors. Deliberately invokes nullable type.
    assertType(findNode.methodInvocation('first').methodName, 'Function?');
  }

  test_mixin_hierarchy() async {
    addTestFile('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A');
    assertType(findNode.typeName('A {} // 2'), 'A');
  }

  test_null_assertion_operator_changes_null_to_never() async {
    addTestFile('''
main() {
  Null x = null;
  x!;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.postfix('x!'), 'Never');
  }

  test_null_assertion_operator_removes_nullability() async {
    addTestFile('''
main() {
  Object? x = null;
  x!;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.postfix('x!'), 'Object');
  }

  @failingTest
  test_parameter_genericFunctionType() async {
    addTestFile('''
main(int? Function(bool, String?)? a) {
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(
      findNode.genericFunctionType('Function('),
      '(bool!, String?) → int??',
    );
  }

  test_parameter_getterNullAwareAccess_interfaceType() async {
    addTestFile(r'''
main(int? x) {
  return x?.isEven;
}
''');

    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_parameter_interfaceType() async {
    addTestFile('''
main(int? a, int b) {
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int');
  }

  test_parameter_interfaceType_generic() async {
    addTestFile('''
main(List<int?>? a, List<int>? b, List<int?> c, List<int> d) {
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('List<int?>? a'), 'List<int?>?');
    assertType(findNode.typeName('List<int>? b'), 'List<int>?');
    assertType(findNode.typeName('List<int?> c'), 'List<int?>');
    assertType(findNode.typeName('List<int> d'), 'List<int>');
  }

  test_parameter_methodNullAwareCall_interfaceType() async {
    await addTestFile(r'''
class C {
  bool x() => true;
}

main(C? c) {
  return c?.x();
}
''');

    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_parameter_nullCoalesce_nullableInt_int() async {
    await addTestFile(r'''
main(int? x, int y) {
  x ?? y;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.binary('x ?? y'), 'int');
  }

  test_parameter_nullCoalesce_nullableInt_nullableInt() async {
    await addTestFile(r'''
main(int? x) {
  x ?? x;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.binary('x ?? x'), 'int?');
  }

  test_parameter_nullCoalesceAssign_nullableInt_int() async {
    await addTestFile(r'''
main(int? x, int y) {
  x ??= y;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_parameter_nullCoalesceAssign_nullableInt_nullableInt() async {
    await addTestFile(r'''
main(int? x) {
  x ??= x;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_parameter_typeParameter() async {
    addTestFile('''
main<T>(T a, T? b) {
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('T a'), 'T');
    assertType(findNode.typeName('T? b'), 'T?');
  }

  test_typedef_classic() async {
    addTestFile('''
typedef int? F(bool a, String? b);

main() {
  F? a;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('F? a'), 'int? Function(bool, String?)?');
  }

  @failingTest
  test_typedef_function() async {
    addTestFile('''
typedef F<T> = int? Function(bool, T, T?);

main() {
  F<String>? a;
}
''');
    await resolveTestFile();
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
    addTestFile('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A*');
    assertType(findNode.typeName('A {} // 2'), 'A*');
    assertType(findNode.typeName('A {} // 3'), 'A*');
  }

  test_classTypeAlias_hierarchy() async {
    addTestFile('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A with'), 'A*');
    assertType(findNode.typeName('B implements'), 'B*');
    assertType(findNode.typeName('C;'), 'C*');
  }

  test_local_variable_interfaceType_notMigrated() async {
    addTestFile('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    await resolveTestFile();
    assertTestErrorsWithCodes([ParserErrorCode.EXPERIMENT_NOT_ENABLED]);

    assertType(findNode.typeName('int? a'), 'int*');
    assertType(findNode.typeName('int b'), 'int*');
  }

  test_mixin_hierarchy() async {
    addTestFile('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('A {} // 1'), 'A*');
    assertType(findNode.typeName('A {} // 2'), 'A*');
  }
}
