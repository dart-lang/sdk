// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualTest);
    defineReflectiveTests(EqualWithNullSafetyTest);
    defineReflectiveTests(NotEqualTest);
    defineReflectiveTests(NotEqualWithNullSafetyTest);
  });
}

@reflectiveTest
class EqualTest extends PubPackageResolutionTest {
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
class EqualWithNullSafetyTest extends EqualTest with WithNullSafetyMixin {}

@reflectiveTest
class NotEqualTest extends PubPackageResolutionTest {
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
class NotEqualWithNullSafetyTest extends NotEqualTest with WithNullSafetyMixin {
}
