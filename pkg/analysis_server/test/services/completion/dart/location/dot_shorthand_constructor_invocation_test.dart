// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DotShorthandConstructorInvocationTest);
  });
}

@reflectiveTest
class DotShorthandConstructorInvocationTest extends AbstractCompletionDriverTest
    with DotShorthandConstructorInvocationTestCases {}

mixin DotShorthandConstructorInvocationTestCases
    on AbstractCompletionDriverTest {
  Future<void> test_constructor_const() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  C c = const .^
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_const_difference() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  print(C() != const .^);
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_const_difference_withPrefix() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  print(C.named() != const .n^);
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

  Future<void> test_constructor_const_equality() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  print(C() == const .^);
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_constructor_const_equality_withPrefix() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  print(C.named() == const .n^);
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

  Future<void> test_constructor_const_withPrefix() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  C c = const .n^
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

  Future<void> test_constructor_const_withPrefix_parentheses() async {
    allowedIdentifiers = {'named', 'notConstant'};
    await computeSuggestions('''
class C {
  const C.named();
  C.notConstant();
}
void f() {
  C c = const .n^()
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

  Future<void> test_invalid_type() async {
    // https://github.com/dart-lang/language/issues/4606#issuecomment-3753427148
    newFile(join(testPackageLibPath, 'private.dart'), '''
class _C {
  const _C();
}

void foo(_C c) {}
''');
    await computeSuggestions('''
import 'private.dart';

void f() {
  foo(const .^);
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_invalid_type_typedef() async {
    // https://github.com/dart-lang/language/issues/4606#issuecomment-3753427148
    newFile(join(testPackageLibPath, 'private.dart'), '''
class _C {
  const _C();
}

typedef C = _C;

void foo(C c) {}
''');
    await computeSuggestions('''
import 'private.dart';

void f() {
  foo(const .^);
}
''');
    assertResponse(r'''
suggestions
''');
  }
}
