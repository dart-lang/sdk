// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectingConstructorInvocationTest);
  });
}

@reflectiveTest
class RedirectingConstructorInvocationTest extends AbstractCompletionDriverTest
    with RedirectingConstructorInvocationTestCases {}

mixin RedirectingConstructorInvocationTestCases
    on AbstractCompletionDriverTest {
  Future<void> test_afterKeyword_noArgumentList() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this^
}
''');
    assertResponse(r'''
replacement
  left: 4
suggestions
  this
    kind: keyword
''');
  }

  Future<void> test_afterKeyword_withArgumentList() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this^();
}
''');
    assertResponse(r'''
replacement
  left: 4
suggestions
''');
  }

  Future<void> test_afterPeriod_noArgumentList_noPrefix() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this.^
}
''');
    assertResponse(r'''
suggestions
  n0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_noArgumentList_prefix() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this.n^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  n0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_withArgumentList_noPrefix() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this.^();
}
''');
    assertResponse(r'''
suggestions
  n0
    kind: constructorInvocation
''');
  }

  Future<void> test_afterPeriod_withArgumentList_prefix() async {
    await computeSuggestions('''
class C {
  C();
  C.n0();
  C.n1() : this.n^();
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  n0
    kind: constructorInvocation
''');
  }
}
