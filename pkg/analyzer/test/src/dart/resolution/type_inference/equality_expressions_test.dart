// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualTest);
    defineReflectiveTests(NotEqualTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class EqualTest extends PubPackageResolutionTest {
  test_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object a, Object b) {
  var c = a == b;
  print(c);
}
''');
    assertType(result.findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class NotEqualTest extends PubPackageResolutionTest {
  test_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object a, Object b) {
  var c = a != b;
  print(c);
}
''');
    assertType(result.findNode.simple('c)'), 'bool');
  }
}
