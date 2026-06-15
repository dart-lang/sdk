// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({int x = 0});
}
main() {
  const A(0);
//        ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_class_constConstructor_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({int x = 0});
}
class B extends A {
  const B() : super(0);
//                  ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_class_constConstructor_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A({int x = 0});
}
typedef B = A;
main() {
  const B(0);
//        ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_context() async {
    // No context type should be supplied when type inferring an extra
    // positional argument, even if there is an unmatched name parameter.
    var result = await resolveTestCodeWithDiagnostics(r'''
T f<T>() => throw '$T';
g({int? named}) {}
main() {
  g(f());
//  ^^^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
}
''');
    assertType(
      result.findNode.methodInvocation('f()').typeArgumentTypes!.single,
      'dynamic',
    );
  }

  test_functionExpressionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (int x, {int y = 0}) {} (0, 1);
//                            ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 1 expected, but 2 found.
}
''');
  }

  test_metadata_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
//  ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
  const E({int? a});
//              ^
// [diag.unusedElementParameter] A value for optional parameter 'a' isn't ever given.
}
''');
  }

  test_metadata_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type const A(int it) {}

@A(0, 1)
//    ^
// [diag.extraPositionalArguments] Too many positional arguments: 1 expected, but 2 found.
void f() {}
''');
  }

  test_methodInvocation_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f({x, y}) {}
main() {
  f(0, 1, '2');
//  ^
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 3 found.
}
''');
  }

  test_partiallyTypedName() async {
    await resolveTestCodeWithDiagnostics(r'''
f({int xx = 0, int yy = 0, int zz = 0}) {}

main() {
  f(xx: 1, yy: 2, z);
//                ^
// [diag.undefinedIdentifier] Undefined name 'z'.
// [diag.extraPositionalArgumentsCouldBeNamed] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends PubPackageResolutionTest {
  test_constConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
main() {
  const A(0);
//        ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_constConstructor_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
//                  ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0)
//  ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');
  }

  test_functionExpressionInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  (int x) {} (0, 1);
//               ^
// [diag.extraPositionalArguments] Too many positional arguments: 1 expected, but 2 found.
}
''');
  }

  test_methodInvocation_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {}
main() {
  f(0, 1, '2');
//  ^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 3 found.
}
''');
  }
}
