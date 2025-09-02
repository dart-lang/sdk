// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierTest);
  });
}

@reflectiveTest
class UndefinedIdentifierTest extends PubPackageResolutionTest {
  test_annotation_references_static_method_in_class() async {
    await assertErrorsInCode(
      '''
@Annotation(foo)
class C {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 12, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 12, 3),
      ],
    );
  }

  test_annotation_references_static_method_in_class_from_type_parameter() async {
    // It not is allowed for an annotation of a class type parameter to refer to
    // a method in a class.
    await assertErrorsInCode(
      '''
class C<@Annotation(foo) T> {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 20, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 20, 3),
      ],
    );
  }

  test_annotation_references_static_method_in_extension() async {
    await assertErrorsInCode(
      '''
@Annotation(foo)
extension E on int {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 12, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 12, 3),
      ],
    );
  }

  test_annotation_references_static_method_in_extension_from_type_parameter() async {
    // It is not allowed for an annotation of an extension type parameter to
    // refer to a method in a class.
    await assertErrorsInCode(
      '''
extension E<@Annotation(foo) T> on T {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''',
      [
        error(CompileTimeErrorCode.constWithNonConstantArgument, 24, 3),
        error(CompileTimeErrorCode.undefinedIdentifier, 24, 3),
      ],
    );
  }

  test_annotation_references_static_method_in_mixin() async {
    await assertErrorsInCode(
      '''
@Annotation(foo)
mixin M {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 12, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 12, 3),
      ],
    );
  }

  test_annotation_references_static_method_in_mixin_from_type_parameter() async {
    // It is not allowed for an annotation of a mixin type parameter to refer to
    // a method in a class.
    await assertErrorsInCode(
      '''
mixin M<@Annotation(foo) T> {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 20, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 20, 3),
      ],
    );
  }

  test_annotation_uses_scope_resolution_class() async {
    // If an annotation on a class type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await assertErrorsInCode(
      '''
class C<@Annotation.function(foo) @Annotation.type(B) T> {
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 29, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 29, 3),
      ],
    );
  }

  test_annotation_uses_scope_resolution_extension() async {
    // If an annotation on an extension type parameter cannot be resolved using
    // the normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await assertErrorsInCode(
      '''
extension E<@Annotation.function(foo) @Annotation.type(B) T> on C {}
class C {
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''',
      [
        error(CompileTimeErrorCode.constWithNonConstantArgument, 33, 3),
        error(CompileTimeErrorCode.undefinedIdentifier, 33, 3),
      ],
    );
  }

  test_annotation_uses_scope_resolution_mixin() async {
    // If an annotation on a mixin type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await assertErrorsInCode(
      '''
mixin M<@Annotation.function(foo) @Annotation.type(B) T> {
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 29, 3),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 29, 3),
      ],
    );
  }

  test_assignedPatternVariable() async {
    await assertErrorsInCode(
      '''
void f() {
  (x) = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 14, 1)],
    );
  }

  @failingTest
  test_commentReference() async {
    await assertErrorsInCode(
      '''
/** [m] xxx [new B.c] */
class A {
}''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 5, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 17, 1),
      ],
    );
  }

  test_compoundAssignment_noGetter_hasSetter() async {
    await assertErrorsInCode(
      '''
set foo(int _) {}

void f() {
  foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 32, 3)],
    );
  }

  test_compoundAssignment_noGetter_noSetter() async {
    await assertErrorsInCode(
      '''
void f() {
  foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 13, 3)],
    );
  }

  test_for() async {
    await assertErrorsInCode(
      '''
f(var l) {
  for (e in l) {
  }
}''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 18, 1)],
    );
  }

  test_forElement_inList_insideElement() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [for(int x in []) x, null];
}
''');
  }

  test_forElement_inList_outsideElement() async {
    await assertErrorsInCode(
      '''
f() {
  return [for (int x in []) null, x];
}
''',
      [
        error(WarningCode.unusedLocalVariable, 25, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 40, 1),
      ],
    );
  }

  test_forStatement_ForPartsWithDeclarations_initializer() async {
    await assertErrorsInCode(
      '''
void f() {
  for (var x = x;;) {
    x;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 26, 1)],
    );
  }

  test_forStatement_inBody() async {
    await assertNoErrorsInCode('''
f() {
  for (int x in []) {
    x;
  }
}
''');
  }

  test_forStatement_outsideBody() async {
    await assertErrorsInCode(
      '''
f() {
  for (int x in []) {}
  x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 17, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 31, 1),
      ],
    );
  }

  test_function() async {
    await assertErrorsInCode(
      '''
int a() => b;
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 11, 1)],
    );
  }

  test_get_from_external_variable_final_valid() async {
    await assertNoErrorsInCode('''
external final int x;
int f() => x;
''');
  }

  test_get_from_external_variable_valid() async {
    await assertNoErrorsInCode('''
external int x;
int f() => x;
''');
  }

  test_importCore_withShow() async {
    await assertErrorsInCode(
      '''
import 'dart:core' show List;
main() {
  List;
  String;
}''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 49, 6)],
    );
  }

  test_inheritedGetter_shadowedBy_topLevelSetter() async {
    await assertErrorsInCode(
      '''
class A {
  int get foo => 0;
}

void set foo(int _) {}

class B extends A {
  void bar() {
    foo;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 96, 3)],
    );
  }

  test_initializer() async {
    await assertErrorsInCode(
      '''
var a = b;
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 8, 1)],
    );
  }

  test_methodInvocation() async {
    await assertErrorsInCode(
      '''
f() { C.m(); }
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 6, 1)],
    );
  }

  test_postfixExpression_increment_noGetter_hasSetter() async {
    await assertErrorsInCode(
      '''
set foo(int _) {}

void f() {
  foo++;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 32, 3)],
    );
  }

  test_prefixExpression_increment_noGetter_hasSetter() async {
    await assertErrorsInCode(
      '''
set foo(int _) {}

void f() {
  ++foo;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 34, 3)],
    );
  }

  test_private_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode(
      '''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
  }
}''',
      [
        error(WarningCode.unusedLocalVariable, 58, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 62, 4),
      ],
    );
  }

  test_private_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode(
      '''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
  }
}''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 54, 4)],
    );
  }

  test_set_external_variable_valid() async {
    await assertNoErrorsInCode('''
external int x;
void f(int value) {
  x = value;
}
''');
  }

  test_synthetic_whenExpression_defined() async {
    await assertErrorsInCode(
      r'''
print(x) {}
main() {
  print(is String);
}
''',
      [error(ParserErrorCode.missingIdentifier, 29, 2)],
    );
  }

  test_synthetic_whenMethodName_defined() async {
    await assertErrorsInCode(
      r'''
print(x) {}
void f(int p) {
  p.();
}
''',
      [
        error(ParserErrorCode.missingIdentifier, 32, 1),
        error(CompileTimeErrorCode.undefinedGetter, 32, 1),
      ],
    );
  }
}
