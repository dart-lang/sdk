// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonExhaustiveSwitchExpressionTest);
    defineReflectiveTests(NonExhaustiveSwitchStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonExhaustiveSwitchExpressionTest extends PubPackageResolutionTest {
  test_bool_true() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(bool x) {
  return switch (x) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type 'bool' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'false'.
    true => 0,
  };
}
''');
  }

  test_bool_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(bool x) {
  return switch (x) {
    true => 1,
    false => 0,
  };
}
''');
  }

  test_class_int_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(int x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
  }

  test_class_withField_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(int x) {
  return switch (x) {
    int(isEven: true) => 0,
    _ => 1,
  };
}
''');
  }

  test_enum_2at2_hasWhen() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b
}

Object f(E x) {
  return switch (x) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.a'.
    E.a when 1 == 0 => 0,
    E.b => 1,
  };
}
''');
  }

  test_invalidType_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Unresolved x) => switch (x) {};
//     ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');
  }

  test_private_enum() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum _E { a, b }
_E e() => _E.a;
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

Object f() {
  return switch (e()) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpressionPrivate] The enum '_E' isn't exhaustively matched by the switch cases because some of the enum constants are private.
  };
}
''');
  }

  test_private_enum_sameLibrary() async {
    await resolveTestCodeWithDiagnostics('''
enum _E { a, b }
//        ^
// [diag.unusedField] The value of the field 'a' isn't used.
//           ^
// [diag.unusedField] The value of the field 'b' isn't used.

Object f(_E e) {
  return switch (e) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type '_E' isn't exhaustively matched by the switch cases since it doesn't match the pattern '_E.a'.
  };
}
''');
  }

  test_private_enumConstant() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum E { a, b, _c }
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

Object f(E e) {
  return switch (e) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
    E.a => 0,
  };
}
''');
  }

  test_private_enumConstant_only() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum E { a, b, _c }
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

Object f(E e) {
  return switch (e) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpressionPrivate] The enum 'E' isn't exhaustively matched by the switch cases because some of the enum constants are private.
    E.a => 0,
    E.b => 1,
  };
}
''');
  }

  test_private_enumConstant_sameLibrary() async {
    await resolveTestCodeWithDiagnostics('''
enum E { a, b, _c }
//             ^^
// [diag.unusedField] The value of the field '_c' isn't used.
Object f(E e) {
  return switch (e) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E._c'.
    E.a => 0,
    E.b => 1,
  };
}
''');
  }

  test_private_sealed() async {
    newFile(join(testPackageLibPath, 'private_sealed.dart'), r'''
sealed class _A {}
class B extends _A {}
_A a() => B();
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_sealed.dart';

Object f() {
  return switch (a()) {
//       ^^^^^^
// [diag.nonExhaustiveSwitchExpression] The type '_A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'B()'.
  };
}
''');
  }
}

@reflectiveTest
class NonExhaustiveSwitchStatementTest extends PubPackageResolutionTest {
  test_alwaysExhaustive_bool_true() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'bool' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'false'.
    case true:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
    case bool _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'bool' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'true'.
    case int _:
//       ^^^
// [diag.patternNeverMatchesValueType] The matched value type 'bool' can never match the required type 'int'.
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_untyped() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_boolNullable_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool? x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'bool?' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'null'.
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_boolNullable_true_false_null() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool? x) {
  switch (x) {
    case true:
    case false:
    case null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at1() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
    case E.a:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at2_cases() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at2_hasWhen() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.a'.
    case E.a when 1 == 0:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at2_logicalOr() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a || E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_cannotCompute() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v1(v2), v2(v1);
//^^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
//        ^^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
  const E(Object f);
}

void f(E x) {
  switch (x) {
    case E.v1:
    case E.v2:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_Null_hasError() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  switch (x) {}
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'Null' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'null'.
}
''');
  }

  test_alwaysExhaustive_Null_noError() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null x) {
  switch (x) {
    case null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_recordType_bool_bool_4at4() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((bool, bool) x) {
  switch (x) {
    case (false, false):
    case (false, true):
    case (true, false):
    case (true, true):
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at1() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'C()'.
    case B():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at2() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case C():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at2_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_constraintsMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}

class B extends A {}

mixin M on A {}

void f(A x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'M()'.
    case B _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_hasExtensionType_1of1() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
extension type EA(A it) implements A {}

void f(A x) {
  switch (x) {
    case B():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_hasExtensionType_1of2() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
class C extends A {}
extension type EA(A it) implements A {}

void f(A x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'C()'.
    case B():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_implementedByEnum_3at2() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}

class B implements A {}

enum E implements A {
  a, b
}

void f(A x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
    case B _:
    case E.a:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_implementedByEnum_3at3() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}

class B implements A {}

enum E implements A {
  a, b
}

void f(A x) {
  switch (x) {
    case B _:
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_implementedByMixin_2at1() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}

class B implements A {}

mixin M implements A {}

void f(A x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'M()'.
    case B _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_implementedByMixin_2at2() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}

class B implements A {}

mixin M implements A {}

void f(A x) {
  switch (x) {
    case B _:
    case M _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_unresolvedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}

void f(A x) {
  switch (x) {
    case unresolved:
//       ^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_unresolvedObject() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}

void f(A x) {
  switch (x) {
    case Unresolved():
//       ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
      break;
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends bool>(T x) {
  switch (x) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'T' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'false'.
    case true:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T extends bool>(T x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_promoted_bool_true() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
//  ^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'T & bool' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'false'.
      case true:
        break;
    }
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_promoted_bool_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
      case true:
      case false:
        break;
    }
  }
}
''');
  }

  test_invalidType_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Unresolved x) {
//     ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  switch (x) {}
}
''');
  }

  test_notAlwaysExhaustive_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
  }

  test_private_enum() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum _E { a, b }
_E e() => _E.a;
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

void f() {
  switch (e()) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatementPrivate] The enum '_E' isn't exhaustively matched by the switch cases because some of the enum constants are private.
  }
}
''');
  }

  test_private_enumConstant() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum E { a, b, _c }
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

void f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
    case E.a:
      break;
  }
}
''');
  }

  test_private_enumConstant_only() async {
    newFile(join(testPackageLibPath, 'private_enum.dart'), r'''
enum E { a, b, _c }
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_enum.dart';

void f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatementPrivate] The enum 'E' isn't exhaustively matched by the switch cases because some of the enum constants are private.
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_private_sealed() async {
    newFile(join(testPackageLibPath, 'private_sealed.dart'), r'''
sealed class _A {}
class B extends _A {}
_A a() => B();
''');
    await resolveTestCodeWithDiagnostics('''
import 'private_sealed.dart';

Object f() {
  switch (a()) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type '_A' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'B()'.
  }
}
''');
  }
}
