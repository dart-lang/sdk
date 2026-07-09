// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends PubPackageResolutionTest {
  test_annotation_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.named(int p);
}
@A.named()
//       ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'named', but 0 found.
void f() {
}
''');
  }

  test_annotation_withArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
@A()
// ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
void f() {
}
''');
  }

  test_annotation_withoutArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
const a = A();
//          ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
@a
void f() {
}
''');
  }

  test_enumConstant_withArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v();
//  ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'E', but 0 found.
  const E(int a);
}
''');
  }

  test_enumConstant_withoutArgumentList() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
//^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'E', but 0 found.
  const E(int a);
}
''');
  }

  test_functionExpressionInvocation_getter() async {
    await resolveTestCodeWithDiagnostics('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
//       ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'getter', but 0 found.
}''');
  }

  test_functionExpressionInvocation_plural() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  (int x, int y) {} ();
//                   ^
// [diag.notEnoughPositionalArgumentsPlural] 2 positional arguments expected, but 0 found.
}''');
  }

  test_functionExpressionInvocation_singular() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  (int x) {} ();
//            ^
// [diag.notEnoughPositionalArgumentsSingular] 1 positional argument expected, but 0 found.
}''');
  }

  test_instanceCreationExpression_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
main() {
  const A();
//        ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_instanceCreationExpression_const_namedArgument_insteadOfRequiredPositional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
main() {
  const A(p: 0);
//        ^
// [diag.undefinedNamedParameter] The named parameter 'p' isn't defined.
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_instanceCreationExpression_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int x, int y, {int? n});
}

void f() {
  A.named(5, n: 1);
//         ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'named', but 1 found.
}
''');
  }

  test_instanceCreationExpression_positionalAndNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x, int y, {int? n});
}

void f() {
  A(5, n: 1);
//   ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'A.new', but 1 found.
}
''');
  }

  test_methodInvocation_function() async {
    await resolveTestCodeWithDiagnostics('''
f(int a, String b) {}
main() {
  f();
//  ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'f', but 0 found.
}''');
  }

  test_redirectingConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
  const A.named(int p) : this();
//                            ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_redirectingConstructorInvocation_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.named(int p);
  const A(int p) : this.named();
//                            ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'named', but 0 found.
}
''');
  }

  test_superConstructorInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
//                  ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'A.new', but 0 found.
}
''');
  }

  test_superConstructorInvocation_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A.named(int p);
}
class B extends A {
  const B() : super.named();
//                        ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'named', but 0 found.
}
''');
  }

  test_superConstructorInvocation_superParameter_optional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}

class B extends A {
  B([super.a]) : super();
}
''');
  }

  test_superConstructorInvocation_superParameter_required() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }
}
