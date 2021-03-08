// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../completion_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorCompletionTest);
  });
}

@reflectiveTest
class ConstructorCompletionTest extends CompletionTestCase {
  Future<void> test_constructor_abstract() async {
    addTestFile('''
void f() {
  g(^);
}
void g(C c) {}
abstract class C {
  C.c();
}
''');
    assertHasNoCompletion('C.c');
  }
}
