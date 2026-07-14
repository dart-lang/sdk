// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedIdentifierTest extends PubPackageResolutionTest {
  test_annotation_references_static_method_in_class() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
class C {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_annotation_references_static_method_in_class_from_type_parameter() async {
    // It not is allowed for an annotation of a class type parameter to refer to
    // a method in a class.
    await resolveTestCodeWithDiagnostics('''
class C<@Annotation(foo) T> {
//                  ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_annotation_references_static_method_in_extension() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
extension E on int {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_annotation_references_static_method_in_extension_from_type_parameter() async {
    // It is not allowed for an annotation of an extension type parameter to
    // refer to a method in a class.
    await resolveTestCodeWithDiagnostics('''
extension E<@Annotation(foo) T> on T {
//                      ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_annotation_references_static_method_in_mixin() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
mixin M {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_annotation_references_static_method_in_mixin_from_type_parameter() async {
    // It is not allowed for an annotation of a mixin type parameter to refer to
    // a method in a class.
    await resolveTestCodeWithDiagnostics('''
mixin M<@Annotation(foo) T> {
//                  ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_annotation_uses_scope_resolution_class() async {
    // If an annotation on a class type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
class C<@Annotation.function(foo) @Annotation.type(B) T> {
//                           ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  test_annotation_uses_scope_resolution_extension() async {
    // If an annotation on an extension type parameter cannot be resolved using
    // the normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
extension E<@Annotation.function(foo) @Annotation.type(B) T> on C {}
//                               ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
class C {
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  test_annotation_uses_scope_resolution_mixin() async {
    // If an annotation on a mixin type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
mixin M<@Annotation.function(foo) @Annotation.type(B) T> {
//                           ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  test_assignedPatternVariable() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  (x) = 0;
// ^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
  }

  @FailingTest() // TODO(scheglov): review this
  test_commentReference() async {
    await resolveTestCodeWithDiagnostics('''
/** [m] xxx [new B.c] */
//   ^
// [diag.undefinedIdentifier] Undefined name 'm'.
//               ^
// [diag.undefinedIdentifier] Undefined name 'B'.
class A {
}''');
  }

  test_compoundAssignment_noGetter_hasSetter() async {
    await resolveTestCodeWithDiagnostics('''
set foo(int _) {}

void f() {
  foo += 0;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');
  }

  test_compoundAssignment_noGetter_noSetter() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  foo += 0;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');
  }

  test_for() async {
    await resolveTestCodeWithDiagnostics('''
f(l) {
  for (e in l) {
//     ^
// [diag.undefinedIdentifier] Undefined name 'e'.
  }
}''');
  }

  test_forElement_inList_insideElement() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return [for(int x in []) x, null];
}
''');
  }

  test_forElement_inList_outsideElement() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  return [for (int x in []) null, x];
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                                ^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
  }

  test_forStatement_inBody() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int x in []) {
    x;
  }
}
''');
  }

  test_forStatement_outsideBody() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int x in []) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
  }

  test_function() async {
    await resolveTestCodeWithDiagnostics('''
int a() => b;
//         ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');
  }

  test_get_from_external_variable_final_valid() async {
    await resolveTestCodeWithDiagnostics('''
external final int x;
int f() => x;
''');
  }

  test_get_from_external_variable_valid() async {
    await resolveTestCodeWithDiagnostics('''
external int x;
int f() => x;
''');
  }

  test_importCore_withShow() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:core' show List;
main() {
  List;
  String;
//^^^^^^
// [diag.undefinedIdentifier] Undefined name 'String'.
}''');
  }

  test_inheritedGetter_shadowedBy_topLevelSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

void set foo(int _) {}

class B extends A {
  void bar() {
    foo;
//  ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
  }
}
''');
  }

  test_initializer() async {
    await resolveTestCodeWithDiagnostics('''
var a = b;
//      ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');
  }

  test_methodInvocation() async {
    await resolveTestCodeWithDiagnostics('''
f() { C.m(); }
//    ^
// [diag.undefinedIdentifier] Undefined name 'C'.
''');
  }

  test_postfixExpression_increment_noGetter_hasSetter() async {
    await resolveTestCodeWithDiagnostics('''
set foo(int _) {}

void f() {
  foo++;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');
  }

  test_prefixExpression_increment_noGetter_hasSetter() async {
    await resolveTestCodeWithDiagnostics('''
set foo(int _) {}

void f() {
  ++foo;
//  ^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
}
''');
  }

  test_private_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//          ^^^^
// [diag.undefinedIdentifier] Undefined name '_foo'.
  }
}''');
  }

  test_private_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
//  ^^^^
// [diag.undefinedIdentifier] Undefined name '_foo'.
  }
}''');
  }

  test_set_external_variable_valid() async {
    await resolveTestCodeWithDiagnostics('''
external int x;
void f(int value) {
  x = value;
}
''');
  }

  test_synthetic_whenExpression_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
print(x) {}
main() {
  print(is String);
//      ^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_synthetic_whenMethodName_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
print(x) {}
void f(int p) {
  p.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.undefinedGetter] The getter '(' isn't defined for the type 'int'.
}
''');
  }
}
