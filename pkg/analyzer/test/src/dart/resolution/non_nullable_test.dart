// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableTest);
  });
}

@reflectiveTest
class NonNullableTest extends DriverResolutionTest {
  static const _migrated = "@pragma('analyzer:non-nullable') library test;";

  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  @override
  bool get typeToStringWithNullability => true;

  test_local_parameter_interfaceType() async {
    addTestFile('''
$_migrated
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
$_migrated
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

  test_local_variable_interfaceType() async {
    addTestFile('''
$_migrated
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
$_migrated
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

  test_local_variable_interfaceType_notMigrated() async {
    addTestFile('''
main() {
  int? a = 0;
  int b = 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();

    assertType(findNode.typeName('int? a'), 'int?');
    assertType(findNode.typeName('int b'), 'int*');
  }
}
