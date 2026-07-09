// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsNotTest);
    defineReflectiveTests(IsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IsNotTest extends PubPackageResolutionTest {
  test_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object a) {
  var b = a is! String;
  print(b);
}
''');
    assertType(result.findNode.simple('b)'), 'bool');
  }
}

@reflectiveTest
class IsTest extends PubPackageResolutionTest {
  test_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object a) {
  var b = a is String;
  print(b);
}
''');
    assertType(result.findNode.simple('b)'), 'bool');
  }
}
