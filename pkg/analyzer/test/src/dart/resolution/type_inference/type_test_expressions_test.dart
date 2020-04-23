// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsNotTest);
    defineReflectiveTests(IsNotWithNnbdTest);
    defineReflectiveTests(IsTest);
    defineReflectiveTests(IsWithNnbdTest);
  });
}

@reflectiveTest
class IsNotTest extends DriverResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a) {
  var b = a is! String;
  print(b);
}
''');
    assertType(findNode.simple('b)'), 'bool');
  }
}

@reflectiveTest
class IsNotWithNnbdTest extends IsNotTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}

@reflectiveTest
class IsTest extends DriverResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a) {
  var b = a is String;
  print(b);
}
''');
    assertType(findNode.simple('b)'), 'bool');
  }
}

@reflectiveTest
class IsWithNnbdTest extends IsTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}
