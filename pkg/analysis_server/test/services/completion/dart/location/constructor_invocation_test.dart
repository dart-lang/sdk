// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorInvocationTest);
  });
}

@reflectiveTest
class ConstructorInvocationTest extends AbstractCompletionDriverTest
    with ConstructorInvocationTestCases {}

mixin ConstructorInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_extensionType() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
extension type C(int x) {
  C.named(this.x);
}
void f() {
  C c = C.^
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_extensionType_withPrefix() async {
    allowedIdentifiers = {'named'};
    await computeSuggestions('''
extension type C(int x) {
  C.named(this.x);
}
void f() {
  C c = C.n^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_it() async {
    await computeSuggestions('''
class C {
  C.c1();
}

void f() {
  C.^
}
''');
    assertResponse(r'''
suggestions
  c1
    kind: constructorInvocation
''');
  }
}
