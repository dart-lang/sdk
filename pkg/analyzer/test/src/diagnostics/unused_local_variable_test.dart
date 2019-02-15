// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedLocalVariableTest);
  });
}

@reflectiveTest
class UnusedLocalVariableTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_inFor_underscore_ignored() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
main() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
      // do something
    }
  }
}
''');
  }

  test_inFunction() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v = 2;
}
''', [HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_inMethod() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
class A {
  foo() {
    var v = 1;
    v = 2;
  }
}
''', [HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_isInvoked() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
typedef Foo();
main() {
  Foo foo;
  foo();
}
''');
  }

  test_isNullAssigned() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
typedef Foo();
main() {
  var v;
  v ??= doSomething();
}
doSomething() => 42;
''');
  }

  test_isRead_notUsed_compoundAssign() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v += 2;
}
''', [HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_isRead_notUsed_postfixExpr() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v++;
}
''', [HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_isRead_notUsed_prefixExpr() async {
    enableUnusedLocalVariable = true;
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  ++v;
}
''', [HintCode.UNUSED_LOCAL_VARIABLE]);
  }

  test_isRead_usedArgument() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}
''');
  }

  test_isRead_usedInvocationTarget() async {
    enableUnusedLocalVariable = true;
    await assertNoErrorsInCode(r'''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
  }
}
