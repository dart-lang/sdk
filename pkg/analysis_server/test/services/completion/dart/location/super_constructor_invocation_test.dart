// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperConstructorInvocationTest);
  });
}

@reflectiveTest
class SuperConstructorInvocationTest extends AbstractCompletionDriverTest
    with SuperConstructorInvocationTestCases {}

mixin SuperConstructorInvocationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterKeyword_noArgumentList() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super^
}
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
  super
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_withArgumentList() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super^();
}
''');
    assertResponse(r'''
replacement
  left: 5
suggestions
''');
  }

  Future<void> test_afterPeriod_noArgumentList_noPrefix() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super.^
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_noArgumentList_prefix() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super.b^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_withArgumentList_noPrefix() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super.^();
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_withArgumentList_prefix() async {
    await computeSuggestions('''
class B {
  B.b0();
}
class C extends B {
  C() : super.b^();
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: constructorInvocation
''');
  }
}
