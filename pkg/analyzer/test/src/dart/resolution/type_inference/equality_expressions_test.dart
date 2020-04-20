// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualTest);
    defineReflectiveTests(EqualWithNnbdTest);
    defineReflectiveTests(NotEqualTest);
    defineReflectiveTests(NotEqualWithNnbdTest);
  });
}

@reflectiveTest
class EqualTest extends DriverResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a, Object b) {
  var c = a == b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class EqualWithNnbdTest extends EqualTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}

@reflectiveTest
class NotEqualTest extends DriverResolutionTest {
  test_simple() async {
    await resolveTestCode('''
void f(Object a, Object b) {
  var c = a != b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class NotEqualWithNnbdTest extends NotEqualTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @override
  bool get typeToStringWithNullability => true;
}
