// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
  test_class_constConstructor() async {
    await assertErrorsInCode(
      r'''
class A {
  const A({int x = 0});
}
main() {
  const A(0);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 55, 1)],
    );
  }

  test_class_constConstructor_super() async {
    await assertErrorsInCode(
      r'''
class A {
  const A({int x = 0});
}
class B extends A {
  const B() : super(0);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 76, 1)],
    );
  }

  test_class_constConstructor_typedef() async {
    await assertErrorsInCode(
      r'''
class A {
  const A({int x = 0});
}
typedef B = A;
main() {
  const B(0);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 70, 1)],
    );
  }

  test_context() async {
    // No context type should be supplied when type inferring an extra
    // positional argument, even if there is an unmatched name parameter.
    await assertErrorsInCode(
      r'''
T f<T>() => throw '$T';
g({int? named}) {}
main() {
  g(f());
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 56, 3)],
    );
    assertType(
      findNode.methodInvocation('f()').typeArgumentTypes!.single,
      'dynamic',
    );
  }

  test_functionExpressionInvocation() async {
    await assertErrorsInCode(
      '''
main() {
  (int x, {int y = 0}) {} (0, 1);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 39, 1)],
    );
  }

  test_metadata_enumConstant() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0);
  const E({int? a});
}
''',
      [
        error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 13, 1),
        error(WarningCode.unusedElementParameter, 33, 1),
      ],
    );
  }

  test_metadata_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type const A(int it) {}

@A(0, 1)
void f() {}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 41, 1)],
    );
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode(
      '''
f({x, y}) {}
main() {
  f(0, 1, '2');
}
''',
      [error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 26, 1)],
    );
  }

  test_partiallyTypedName() async {
    await assertErrorsInCode(
      r'''
f({int xx = 0, int yy = 0, int zz = 0}) {}

main() {
  f(xx: 1, yy: 2, z);
}
''',
      [
        error(CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed, 71, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 71, 1),
      ],
    );
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends PubPackageResolutionTest {
  test_constConstructor() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}
main() {
  const A(0);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 44, 1)],
    );
  }

  test_constConstructor_super() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 65, 1)],
    );
  }

  test_enumConstant() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(0)
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 13, 1)],
    );
  }

  test_functionExpressionInvocation() async {
    await assertErrorsInCode(
      '''
main() {
  (int x) {} (0, 1);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 26, 1)],
    );
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode(
      '''
f() {}
main() {
  f(0, 1, '2');
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 20, 1)],
    );
  }
}
