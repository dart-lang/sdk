// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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

  test_local_parameter_interfaceType() async {
    addTestFile('''
main() {
  f(int? a, int b) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int!');
  }

  test_local_returnType_interfaceType() async {
    addTestFile('''
main() {
  int? f() => 0;
  int g() => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? f'), 'int?');
    assertType(findNode.typeName('int g'), 'int!');
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

  test_local_variable_interfaceType() async {
    addTestFile('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int!');
  }

  test_local_variable_interfaceType_generic() async {
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
    assertType(findNode.typeName('List<int>? b'), 'List<int!>?');
    assertType(findNode.typeName('List<int?> c'), 'List<int?>!');
    assertType(findNode.typeName('List<int> d'), 'List<int!>!');
  }

  test_local_variable_typeParameter() async {
    addTestFile('''
class A<T> {
  main(T a) {
    T? b;
  }
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('T a'), 'T!');
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

    assertType(findNode.typeName('F? a'), '(bool!, String?) → int??');
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
      '(bool!, String!, String?) → int??',
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

    assertType(findNode.typeName('A {} // 1'), 'A!');
    assertType(findNode.typeName('A {} // 2'), 'A!');
    assertType(findNode.typeName('A {} // 3'), 'A!');
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

    assertType(findNode.typeName('A with'), 'A!');
    assertType(findNode.typeName('B implements'), 'B!');
    assertType(findNode.typeName('C;'), 'C!');
  }

  test_local_variable_interfaceType_notMigrated() async {
    addTestFile('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    await resolveTestFile();
    assertTestErrors([ParserErrorCode.EXPERIMENT_NOT_ENABLED]);

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

    assertType(findNode.typeName('A {} // 1'), 'A!');
    assertType(findNode.typeName('A {} // 2'), 'A!');
  }
}
