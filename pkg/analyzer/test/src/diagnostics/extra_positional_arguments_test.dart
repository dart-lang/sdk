// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraPositionalArgumentsCouldBeNamedTest);
    defineReflectiveTests(ExtraPositionalArgumentsTest);
  });
}

@reflectiveTest
class ExtraPositionalArgumentsCouldBeNamedTest
    extends PubPackageResolutionTest {
  test_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x = 0});
}
main() {
  const A(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 55,
          1),
    ]);
  }

  test_constConstructor_super() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x = 0});
}
class B extends A {
  const B() : super(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 76,
          1),
    ]);
  }

  test_constConstructor_typedef() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x = 0});
}
typedef B = A;
main() {
  const B(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 70,
          1),
    ]);
  }

  test_functionExpressionInvocation() async {
    await assertErrorsInCode('''
main() {
  (int x, {int y = 0}) {} (0, 1);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 39,
          1),
    ]);
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode('''
f({x, y}) {}
main() {
  f(0, 1, '2');
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 26,
          1),
    ]);
  }

  test_partiallyTypedName() async {
    await assertErrorsInCode(r'''
f({int xx = 0, int yy = 0, int zz = 0}) {}

main() {
  f(xx: 1, yy: 2, z);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 71,
          1),
      error(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, 71, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 71, 1),
    ]);
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends PubPackageResolutionTest {
  test_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 44, 1),
    ]);
  }

  test_constConstructor_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 65, 1),
    ]);
  }

  test_functionExpressionInvocation() async {
    await assertErrorsInCode('''
main() {
  (int x) {} (0, 1);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 26, 1),
    ]);
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode('''
f() {}
main() {
  f(0, 1, '2');
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 20, 1),
    ]);
  }
}
