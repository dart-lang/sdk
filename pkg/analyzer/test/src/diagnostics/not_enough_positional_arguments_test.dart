// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
  });
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends PubPackageResolutionTest {
  test_annotation_named() async {
    await assertErrorsInCode(
      r'''
class A {
  const A.named(int p);
}
@A.named()
void f() {
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          45,
          1,
          messageContains: ["expected by 'named'"],
        ),
      ],
    );
  }

  test_annotation_withArgumentList() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
@A()
void f() {
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          33,
          1,
          messageContains: ["expected by 'A.new'"],
        ),
      ],
    );
  }

  test_annotation_withoutArgumentList() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
const a = A();
@a
void f() {
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          42,
          1,
          messageContains: ["expected by 'A.new'"],
        ),
      ],
    );
  }

  test_enumConstant_withArgumentList() async {
    await assertErrorsInCode(
      r'''
enum E {
  v();
  const E(int a);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          13,
          1,
          messageContains: ["expected by 'E'"],
        ),
      ],
    );
  }

  test_enumConstant_withoutArgumentList() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E(int a);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          11,
          1,
          messageContains: ["expected by 'E'"],
        ),
      ],
    );
  }

  test_functionExpressionInvocation_getter() async {
    await assertErrorsInCode(
      '''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          66,
          1,
          messageContains: ["expected by 'getter'"],
        ),
      ],
    );
  }

  test_functionExpressionInvocation_plural() async {
    await assertErrorsInCode(
      '''
main() {
  (int x, int y) {} ();
}''',
      [error(CompileTimeErrorCode.notEnoughPositionalArgumentsPlural, 30, 1)],
    );
  }

  test_functionExpressionInvocation_singular() async {
    await assertErrorsInCode(
      '''
main() {
  (int x) {} ();
}''',
      [error(CompileTimeErrorCode.notEnoughPositionalArgumentsSingular, 23, 1)],
    );
  }

  test_instanceCreationExpression_const() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
main() {
  const A();
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          49,
          1,
          messageContains: ["expected by 'A.new'"],
        ),
      ],
    );
  }

  test_instanceCreationExpression_const_namedArgument_insteadOfRequiredPositional() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
main() {
  const A(p: 0);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          49,
          1,
        ),
        error(CompileTimeErrorCode.undefinedNamedParameter, 49, 1),
      ],
    );
  }

  test_instanceCreationExpression_named() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named(int x, int y, {int? n});
}

void f() {
  A.named(5, n: 1);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural,
          70,
          1,
          messageContains: ["expected by 'named'"],
        ),
      ],
    );
  }

  test_instanceCreationExpression_positionalAndNamed() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x, int y, {int? n});
}

void f() {
  A(5, n: 1);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural,
          58,
          1,
          messageContains: [
            "2 positional arguments expected by 'A.new', but 1 found.",
          ],
        ),
      ],
    );
  }

  test_methodInvocation_function() async {
    await assertErrorsInCode(
      '''
f(int a, String b) {}
main() {
  f();
}''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural,
          35,
          1,
          messageContains: ["expected by 'f'"],
        ),
      ],
    );
  }

  test_redirectingConstructorInvocation() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
  const A.named(int p) : this();
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          58,
          1,
          messageContains: ["expected by 'A.new'"],
        ),
      ],
    );
  }

  test_redirectingConstructorInvocation_named() async {
    await assertErrorsInCode(
      r'''
class A {
  const A.named(int p);
  const A(int p) : this.named();
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          64,
          1,
          messageContains: ["expected by 'named'"],
        ),
      ],
    );
  }

  test_superConstructorInvocation() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          70,
          1,
          messageContains: ["expected by 'A.new'"],
        ),
      ],
    );
  }

  test_superConstructorInvocation_named() async {
    await assertErrorsInCode(
      r'''
class A {
  const A.named(int p);
}
class B extends A {
  const B() : super.named();
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
          82,
          1,
          messageContains: ["expected by 'named'"],
        ),
      ],
    );
  }

  test_superConstructorInvocation_superParameter_optional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}

class B extends A {
  B([super.a]) : super();
}
''');
  }

  test_superConstructorInvocation_superParameter_required() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }
}
