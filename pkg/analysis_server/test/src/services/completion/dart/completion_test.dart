// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../completion_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentListCompletionTest);
    defineReflectiveTests(AsExpressionCompletionTest);
    defineReflectiveTests(AssertStatementCompletionTest);
    defineReflectiveTests(ConstructorCompletionTest);
    defineReflectiveTests(DeclaredIdentifierCompletionTest);
    defineReflectiveTests(ExpressionFunctionBodyCompletionTest);
    defineReflectiveTests(ExtensionCompletionTest);
    defineReflectiveTests(FormalParameterCompletionTest);
    defineReflectiveTests(GenericFunctionTypeCompletionTest);
    defineReflectiveTests(GenericTypeAliasCompletionTest);
    defineReflectiveTests(PropertyAccessCompletionTest);
    defineReflectiveTests(RedirectedConstructorCompletionTest);
    defineReflectiveTests(RedirectingConstructorInvocationCompletionTest);
    defineReflectiveTests(ReturnStatementTest);
    defineReflectiveTests(SuperConstructorInvocationCompletionTest);
    defineReflectiveTests(VariableDeclarationListCompletionTest);
  });
}

@reflectiveTest
class ArgumentListCompletionTest extends CompletionTestCase {
  Future<void> test_functionWithVoidReturnType_optionalNamed() async {
    await getTestCodeSuggestions('''
void f(C c) {
  c.m(handler: ^);
}

void g() {}

class C {
  void m({void Function()? handler}) {}
}
''');
    assertHasCompletion('g');
  }

  Future<void> test_functionWithVoidReturnType_requiredPositional() async {
    await getTestCodeSuggestions('''
void f(C c) {
  c.m(^);
}

void g() {}

class C {
  void m(void Function() handler) {}
}
''');
    assertHasCompletion('g');
  }

  Future<void> test_privateStaticField() async {
    await getTestCodeSuggestions('''
extension on int {
  static int _x = 0;

  void g(String s) {
    s.substring(^);
  }
}
''');
    assertHasCompletion('_x');
  }
}

@reflectiveTest
class AsExpressionCompletionTest extends CompletionTestCase {
  Future<void> test_type_dynamic() async {
    await getTestCodeSuggestions('''
void f(Object o) {
  var x = o as ^;
}
''');
    assertHasCompletion('dynamic');
  }
}

@reflectiveTest
class AssertStatementCompletionTest extends CompletionTestCase {
  @failingTest
  Future<void> test_message() async {
    await getTestCodeSuggestions('''
void f() {
  assert(true, ^);
}

const c = <int>[];
''');
    assertHasCompletion('c');
  }
}

@reflectiveTest
class ConstructorCompletionTest extends CompletionTestCase {
  Future<void> test_constructor_abstract() async {
    await getTestCodeSuggestions('''
void f() {
  g(^);
}
void g(C c) {}
abstract class C {
  C.c();
}
''');
    assertHasNoCompletion('C.c');
  }
}

@reflectiveTest
class DeclaredIdentifierCompletionTest extends CompletionTestCase {
  Future<void> test_afterFinal_withIdentifier() async {
    await getTestCodeSuggestions('''
class C {
  void m(List<C> cs) {
    for (final ^ x in cs) {}
  }
}
''');
    assertHasCompletion('C');
  }

  Future<void> test_afterFinal_withoutIdentifier() async {
    await getTestCodeSuggestions('''
class C {
  void m(List<C> cs) {
    for (final ^) {}
  }
}
''');
    assertHasCompletion('C');
  }
}

@reflectiveTest
class ExpressionFunctionBodyCompletionTest extends CompletionTestCase {
  Future<void> test_voidReturn_localFunction() async {
    await getTestCodeSuggestions('''
class C {
  void m() {
    void f() => ^;
  }
}

void g() {}
''');
    assertHasCompletion('g');
  }

  Future<void> test_voidReturn_method() async {
    await getTestCodeSuggestions('''
class C {
  void m() => ^;
}

void g() {}
''');
    assertHasCompletion('g');
  }

  Future<void> test_voidReturn_topLevelFunction() async {
    await getTestCodeSuggestions('''
void f() => ^;

void g() {}
''');
    assertHasCompletion('g');
  }
}

@reflectiveTest
class ExtensionCompletionTest extends CompletionTestCase {
  Future<void> test_explicitTarget_getter_sameUnit() async {
    await getTestCodeSuggestions('''
void f(String s) {
  s.^;
}
extension E on String {
  int get g => length;
}
''');
    assertHasCompletion('g');
  }

  Future<void> test_explicitTarget_method_imported() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
extension E on String {
  void m() {}
}
''');
    await getTestCodeSuggestions('''
import 'lib.dart';
void f(String s) {
  s.^;
}
''');
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inLibrary() async {
    newFile(convertPath('$testPackageLibPath/lib.dart'), '''
part 'test.dart';
extension E on String {
  void m() {}
}
''');
    await getTestCodeSuggestions('''
part of 'lib.dart';
void f(String s) {
  s.^;
}
''');
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inPart() async {
    newFile(convertPath('$testPackageLibPath/part.dart'), '''
part of 'test.dart';
extension E on String {
  void m() {}
}
''');
    await getTestCodeSuggestions('''
part 'part.dart';
void f(String s) {
  s.^;
}
''');
    assertHasCompletion('m');
  }

  @failingTest
  Future<void> test_explicitTarget_method_notImported() async {
    // Available suggestions data doesn't yet have information about extension
    // methods.
    newFile(convertPath('/project/bin/lib.dart'), '''
extension E on String {
  void m() {}
}
''');
    await getTestCodeSuggestions('''
void f(String s) {
  s.^;
}
''');
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_sameUnit() async {
    await getTestCodeSuggestions('''
void f(String s) {
  s.^;
}
extension E on String {
  void m() {}
}
''');
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_setter_sameUnit() async {
    await getTestCodeSuggestions('''
void f(String s) {
  s.^;
}
extension E on String {
  set e(int v) {}
}
''');
    assertHasCompletion('e');
  }

  Future<void> test_implicitTarget_inClass_method_sameUnit() async {
    await getTestCodeSuggestions('''
class C {
  void c() {
    ^
  }
}
extension E on C {
  void m() {}
}
''');
    assertHasCompletion('m');
  }

  Future<void> test_implicitTarget_inExtension_method_sameUnit() async {
    await getTestCodeSuggestions('''
extension E on String {
  void m() {
    ^
  }
}
''');
    assertHasCompletion('m');
  }
}

@reflectiveTest
class FormalParameterCompletionTest extends CompletionTestCase {
  Future<void> test_named_last() async {
    await getTestCodeSuggestions('''
void f({int? a, ^}) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_last_afterCovariant() async {
    await getTestCodeSuggestions('''
void f({covariant ^}) {}
''');
    assertHasNoCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_last_afterRequired() async {
    await getTestCodeSuggestions('''
void f({required ^}) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_only() async {
    await getTestCodeSuggestions('''
void f({^}) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_optionalPositional_last() async {
    await getTestCodeSuggestions('''
void f([int a, ^]) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_optionalPositional_only() async {
    await getTestCodeSuggestions('''
void f([^]) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_requiredPositional_only() async {
    await getTestCodeSuggestions('''
void f(^) {}
''');
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }
}

@reflectiveTest
class GenericFunctionTypeCompletionTest extends CompletionTestCase {
  Future<void> test_returnType_beforeType() async {
    await getTestCodeSuggestions('''
void f({^vo Function() p}) {}
''');
    assertHasCompletion('void');
  }

  Future<void> test_returnType_beforeType_afterRequired() async {
    await getTestCodeSuggestions('''
void f({required ^vo Function() p}) {}
''');
    assertHasCompletion('void');
  }

  Future<void> test_returnType_inType() async {
    await getTestCodeSuggestions('''
void f({v^o Function() p}) {}
''');
    assertHasCompletion('void');
  }

  Future<void> test_returnType_inType_afterRequired() async {
    await getTestCodeSuggestions('''
void f({required v^o Function() p}) {}
''');
    assertHasCompletion('void');
  }

  Future<void> test_returnType_partialFunctionType() async {
    await getTestCodeSuggestions('''
void f({^ Function() p}) {}
''');
    assertHasCompletion('void');
  }

  Future<void> test_returnType_partialFunctionType_afterRequired() async {
    await getTestCodeSuggestions('''
void f({required ^ Function() p}) {}
''');
    assertHasCompletion('void');
  }
}

@reflectiveTest
class GenericTypeAliasCompletionTest extends CompletionTestCase {
  Future<void> test_returnType_void() async {
    await getTestCodeSuggestions('''
typedef F = ^
''');
    assertHasCompletion('void');
  }
}

@reflectiveTest
class PropertyAccessCompletionTest extends CompletionTestCase {
  Future<void> test_nullSafe_extension() async {
    await getTestCodeSuggestions('''
void f(C c) {
  c.a?.^;
}
class C {
  C? get a => null;
}
extension on C {
  int get b => 0;
}
''');
    assertHasCompletion('b');
  }

  Future<void> test_setter_deprecated() async {
    await getTestCodeSuggestions('''
void f(C c) {
  c.^;
}
class C {
  @deprecated
  set x(int x) {}
}
''');
    assertHasCompletion('x',
        elementKind: ElementKind.SETTER, isDeprecated: true);
  }

  Future<void> test_setter_deprecated_withNonDeprecatedGetter() async {
    await getTestCodeSuggestions('''
void f(C c) {
  c.^;
}
class C {
  int get x => 0;
  @deprecated
  set x(int x) {}
}
''');
    assertHasCompletion('x',
        elementKind: ElementKind.GETTER, isDeprecated: false);
  }
}

@reflectiveTest
class RedirectedConstructorCompletionTest extends CompletionTestCase {
  Future<void> test_keywords() async {
    await getTestCodeSuggestions('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    assertHasNoCompletion('assert');
    assertHasNoCompletion('super');
    assertHasNoCompletion('this');
  }

  Future<void> test_namedConstructor_private() async {
    await getTestCodeSuggestions('''
class A {
  factory A() = ^
}
class B implements A {
  B._();
}
''');
    assertHasCompletion('B._');
  }

  Future<void> test_namedConstructor_public() async {
    await getTestCodeSuggestions('''
class A {
  factory A() = ^
}
class B implements A {
  B.b();
}
''');
    assertHasCompletion('B.b');
  }

  Future<void> test_sameConstructor() async {
    await getTestCodeSuggestions('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    assertHasNoCompletion('A');
  }

  Future<void> test_unnamedConstructor() async {
    await getTestCodeSuggestions('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    assertHasCompletion('B');
  }

  @failingTest
  Future<void> test_unnamedConstructor_inDifferentLibrary() async {
    newFile('/project/bin/b.dart', '''
class B implements A {
  B();
}
''');
    await getTestCodeSuggestions('''
import 'b.dart';

class A {
  factory A() = ^
}
''');
    assertHasCompletion('B');
  }
}

@reflectiveTest
class RedirectingConstructorInvocationCompletionTest
    extends CompletionTestCase {
  @failingTest
  Future<void> test_instanceMember() async {
    await getTestCodeSuggestions('''
class C {
  C.c() {}
  C() : this.^
}
''');
    assertHasNoCompletion('toString');
  }

  Future<void> test_namedConstructor_private() async {
    await getTestCodeSuggestions('''
class C {
  C._() {}
  C() : this.^
}
''');
    assertHasCompletion('_');
  }

  Future<void> test_namedConstructor_public() async {
    await getTestCodeSuggestions('''
class C {
  C.c() {}
  C() : this.^
}
''');
    assertHasCompletion('c');
  }

  Future<void> test_sameConstructor() async {
    await getTestCodeSuggestions('''
class C {
  C.c() : this.^
}
''');
    assertHasNoCompletion('c');
  }

  Future<void> test_unnamedConstructor() async {
    await getTestCodeSuggestions('''
class C {
  C() {}
  C.c() : this.^
}
''');
    assertHasNoCompletion('');
  }
}

@reflectiveTest
class ReturnStatementTest extends CompletionTestCase {
  Future<void> test_voidFromVoid_localFunction() async {
    await getTestCodeSuggestions('''
class C {
  void m() {
    void f() {
      return ^
    }
  }
  void g() {}
}
''');
    assertHasCompletion('g');
  }

  Future<void> test_voidFromVoid_method() async {
    await getTestCodeSuggestions('''
class C {
  void f() {
    return ^
  }
  void g() {}
}
''');
    assertHasCompletion('g');
  }

  Future<void> test_voidFromVoid_topLevelFunction() async {
    await getTestCodeSuggestions('''
void f() {
  return ^
}
void g() {}
''');
    assertHasCompletion('g');
  }
}

@reflectiveTest
class SuperConstructorInvocationCompletionTest extends CompletionTestCase {
  Future<void> test_namedConstructor_notVisible() async {
    newFile('/project/bin/a.dart', '''
class A {
  A._() {}
}
''');
    await getTestCodeSuggestions('''
import 'a.dart';

class B extends A {
  B() : super.^
}
''');
    assertHasNoCompletion('_');
  }

  Future<void> test_namedConstructor_private() async {
    await getTestCodeSuggestions('''
class A {
  A._() {}
}
class B extends A {
  B() : super.^
}
''');
    assertHasCompletion('_');
  }

  Future<void> test_namedConstructor_public() async {
    await getTestCodeSuggestions('''
class A {
  A.a() {}
}
class B extends A {
  B() : super.^
}
''');
    assertHasCompletion('a');
  }

  Future<void> test_unnamedConstructor() async {
    await getTestCodeSuggestions('''
class A {
  A() {}
}
class B extends A {
  B() : super.^
}
''');
    assertHasNoCompletion('');
  }
}

@reflectiveTest
class VariableDeclarationListCompletionTest extends CompletionTestCase {
  Future<void> test_type_voidAfterFinal() async {
    await getTestCodeSuggestions('''
class C {
  final ^
}
''');
    assertHasCompletion('void');
  }
}
