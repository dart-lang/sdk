// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../completion_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorCompletionTest);
    defineReflectiveTests(PropertyAccessorCompletionTest);
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
    await getSuggestions();
    assertHasNoCompletion('C.c');
  }
}

@reflectiveTest
class PropertyAccessorCompletionTest extends CompletionTestCase {
  Future<void> test_setter_deprecated() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.SETTER, isDeprecated: true);
  }

  Future<void> test_setter_deprecated_withNonDeprecatedGetter() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  int get x => 0;
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.GETTER, isDeprecated: false);
  }
}
