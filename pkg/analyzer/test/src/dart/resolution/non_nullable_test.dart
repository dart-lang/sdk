// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableTest);
  });
}

@reflectiveTest
class NonNullableTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_interfaceType() async {
    addTestFile(r'''
int v = 0;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var typeName = findNode.typeName('int v');
    expect(typeName.name.name, 'int');
    expect(typeName.question, isNull);
  }

  test_interfaceType_nullable() async {
    addTestFile(r'''
int? v = 0;
''');
    await resolveTestFile();
    assertNoTestErrors();

    var typeName = findNode.typeName('int? v');
    expect(typeName.name.name, 'int');
    expect(typeName.question, isNotNull);
  }
}
