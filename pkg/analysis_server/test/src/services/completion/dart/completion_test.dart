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
    addTestFile('''
void f(C c) {
  c.m(handler: ^);
}

void g() {}

class C {
  void m({void Function()? handler}) {}
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_functionWithVoidReturnType_requiredPositional() async {
    addTestFile('''
void f(C c) {
  c.m(^);
}

void g() {}

class C {
  void m(void Function() handler) {}
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_privateStaticField() async {
    addTestFile('''
extension on int {
  static int _x = 0;

  void g(String s) {
    s.substring(^);
  }
}
''');
    await getSuggestions();
    assertHasCompletion('_x');
  }
}

@reflectiveTest
class AsExpressionCompletionTest extends CompletionTestCase {
  Future<void> test_type_dynamic() async {
    addTestFile('''
void f(Object o) {
  var x = o as ^;
}
''');
    await getSuggestions();
    assertHasCompletion('dynamic');
  }
}

@reflectiveTest
class AssertStatementCompletionTest extends CompletionTestCase {
  @failingTest
  Future<void> test_message() async {
    addTestFile('''
void f() {
  assert(true, ^);
}

const c = <int>[];
''');
    await getSuggestions();
    assertHasCompletion('c');
  }
}

@reflectiveTest
class ConstructorCompletionTest extends CompletionTestCase {
  Future<void> test_constructor_abstract() async {
    addTestFile('''
void f() {
  g(^);
}
void g(C c) {}
abstract class C {
  C.c();
}
''');
    await getSuggestions();
    assertHasNoCompletion('C.c');
  }
}

@reflectiveTest
class DeclaredIdentifierCompletionTest extends CompletionTestCase {
  Future<void> test_afterFinal_withIdentifier() async {
    addTestFile('''
class C {
  void m(List<C> cs) {
    for (final ^ x in cs) {}
  }
}
''');
    await getSuggestions();
    assertHasCompletion('C');
  }

  Future<void> test_afterFinal_withoutIdentifier() async {
    addTestFile('''
class C {
  void m(List<C> cs) {
    for (final ^) {}
  }
}
''');
    await getSuggestions();
    assertHasCompletion('C');
  }
}

@reflectiveTest
class ExpressionFunctionBodyCompletionTest extends CompletionTestCase {
  Future<void> test_voidReturn_localFunction() async {
    addTestFile('''
class C {
  void m() {
    void f() => ^;
  }
}

void g() {}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_voidReturn_method() async {
    addTestFile('''
class C {
  void m() => ^;
}

void g() {}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_voidReturn_topLevelFunction() async {
    addTestFile('''
void f() => ^;

void g() {}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }
}

@reflectiveTest
class ExtensionCompletionTest extends CompletionTestCase {
  Future<void> test_explicitTarget_getter_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  int get g => length;
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_explicitTarget_method_imported() async {
    newFile(convertPath('/project/bin/lib.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
import 'lib.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inLibrary() async {
    newFile(convertPath('/project/bin/lib.dart'), content: '''
part 'test.dart';
extension E on String {
  void m() {}
}
''');
    addTestFile('''
part of 'lib.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inPart() async {
    newFile(convertPath('/project/bin/part.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
part 'part.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  @failingTest
  Future<void> test_explicitTarget_method_notImported() async {
    // Available suggestions data doesn't yet have information about extension
    // methods.
    newFile(convertPath('/project/bin/lib.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  void m() {}
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_setter_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  set e(int v) {}
}
''');
    await getSuggestions();
    assertHasCompletion('e');
  }

  Future<void> test_implicitTarget_inClass_method_sameUnit() async {
    addTestFile('''
class C {
  void c() {
    ^
  }
}
extension E on C {
  void m() {}
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_implicitTarget_inExtension_method_sameUnit() async {
    addTestFile('''
extension E on String {
  void m() {
    ^
  }
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }
}

@reflectiveTest
class FormalParameterCompletionTest extends CompletionTestCase {
  Future<void> test_named_last() async {
    addTestFile('''
void f({int? a, ^}) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_last_afterCovariant() async {
    addTestFile('''
void f({covariant ^}) {}
''');
    await getSuggestions();
    assertHasNoCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_last_afterRequired() async {
    addTestFile('''
void f({required ^}) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_named_only() async {
    addTestFile('''
void f({^}) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_optionalPositional_last() async {
    addTestFile('''
void f([int a, ^]) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_optionalPositional_only() async {
    addTestFile('''
void f([^]) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }

  Future<void> test_requiredPositional_only() async {
    addTestFile('''
void f(^) {}
''');
    await getSuggestions();
    assertHasCompletion('covariant');
    assertHasCompletion('dynamic');
    assertHasNoCompletion('required');
    assertHasCompletion('void');
  }
}

@reflectiveTest
class GenericFunctionTypeCompletionTest extends CompletionTestCase {
  Future<void> test_returnType_beforeType() async {
    addTestFile('''
void f({^vo Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }

  Future<void> test_returnType_beforeType_afterRequired() async {
    addTestFile('''
void f({required ^vo Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }

  Future<void> test_returnType_inType() async {
    addTestFile('''
void f({v^o Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }

  Future<void> test_returnType_inType_afterRequired() async {
    addTestFile('''
void f({required v^o Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }

  Future<void> test_returnType_partialFunctionType() async {
    addTestFile('''
void f({^ Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }

  Future<void> test_returnType_partialFunctionType_afterRequired() async {
    addTestFile('''
void f({required ^ Function() p}) {}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }
}

@reflectiveTest
class GenericTypeAliasCompletionTest extends CompletionTestCase {
  Future<void> test_returnType_void() async {
    addTestFile('''
typedef F = ^
''');
    await getSuggestions();
    assertHasCompletion('void');
  }
}

@reflectiveTest
class PropertyAccessCompletionTest extends CompletionTestCase {
  Future<void> test_nullSafe_extension() async {
    addTestFile('''
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
    await getSuggestions();
    assertHasCompletion('b');
  }

  Future<void> test_setter_deprecated() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.SETTER, isDeprecated: true);
  }

  Future<void> test_setter_deprecated_withNonDeprecatedGetter() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  int get x => 0;
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.GETTER, isDeprecated: false);
  }
}

@reflectiveTest
class RedirectedConstructorCompletionTest extends CompletionTestCase {
  @failingTest
  Future<void> test_keywords() async {
    addTestFile('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    await getSuggestions();
    assertHasNoCompletion('assert');
    assertHasNoCompletion('super');
    assertHasNoCompletion('this');
  }

  Future<void> test_namedConstructor_private() async {
    addTestFile('''
class A {
  factory A() = ^
}
class B implements A {
  B._();
}
''');
    await getSuggestions();
    assertHasCompletion('B._');
  }

  Future<void> test_namedConstructor_public() async {
    addTestFile('''
class A {
  factory A() = ^
}
class B implements A {
  B.b();
}
''');
    await getSuggestions();
    assertHasCompletion('B.b');
  }

  Future<void> test_sameConstructor() async {
    addTestFile('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    await getSuggestions();
    assertHasNoCompletion('A');
  }

  Future<void> test_unnamedConstructor() async {
    addTestFile('''
class A {
  factory A() = ^
}
class B implements A {
  B();
}
''');
    await getSuggestions();
    assertHasCompletion('B');
  }

  @failingTest
  Future<void> test_unnamedConstructor_inDifferentLibrary() async {
    newFile('/project/bin/b.dart', content: '''
class B implements A {
  B();
}
''');
    addTestFile('''
import 'b.dart';

class A {
  factory A() = ^
}
''');
    await getSuggestions();
    assertHasCompletion('B');
  }
}

@reflectiveTest
class RedirectingConstructorInvocationCompletionTest
    extends CompletionTestCase {
  @failingTest
  Future<void> test_instanceMember() async {
    addTestFile('''
class C {
  C.c() {}
  C() : this.^
}
''');
    await getSuggestions();
    assertHasNoCompletion('toString');
  }

  Future<void> test_namedConstructor_private() async {
    addTestFile('''
class C {
  C._() {}
  C() : this.^
}
''');
    await getSuggestions();
    assertHasCompletion('_');
  }

  Future<void> test_namedConstructor_public() async {
    addTestFile('''
class C {
  C.c() {}
  C() : this.^
}
''');
    await getSuggestions();
    assertHasCompletion('c');
  }

  Future<void> test_sameConstructor() async {
    addTestFile('''
class C {
  C.c() : this.^
}
''');
    await getSuggestions();
    assertHasNoCompletion('c');
  }

  Future<void> test_unnamedConstructor() async {
    addTestFile('''
class C {
  C() {}
  C.c() : this.^
}
''');
    await getSuggestions();
    assertHasNoCompletion('');
  }
}

@reflectiveTest
class ReturnStatementTest extends CompletionTestCase {
  Future<void> test_voidFromVoid_localFunction() async {
    addTestFile('''
class C {
  void m() {
    void f() {
      return ^
    }
  }
  void g() {}
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_voidFromVoid_method() async {
    addTestFile('''
class C {
  void f() {
    return ^
  }
  void g() {}
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_voidFromVoid_topLevelFunction() async {
    addTestFile('''
void f() {
  return ^
}
void g() {}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }
}

@reflectiveTest
class SuperConstructorInvocationCompletionTest extends CompletionTestCase {
  Future<void> test_namedConstructor_notVisible() async {
    newFile('/project/bin/a.dart', content: '''
class A {
  A._() {}
}
''');
    addTestFile('''
import 'a.dart';

class B extends A {
  B() : super.^
}
''');
    await getSuggestions();
    assertHasNoCompletion('_');
  }

  Future<void> test_namedConstructor_private() async {
    addTestFile('''
class A {
  A._() {}
}
class B extends A {
  B() : super.^
}
''');
    await getSuggestions();
    assertHasCompletion('_');
  }

  Future<void> test_namedConstructor_public() async {
    addTestFile('''
class A {
  A.a() {}
}
class B extends A {
  B() : super.^
}
''');
    await getSuggestions();
    assertHasCompletion('a');
  }

  Future<void> test_unnamedConstructor() async {
    addTestFile('''
class A {
  A() {}
}
class B extends A {
  B() : super.^
}
''');
    await getSuggestions();
    assertHasNoCompletion('');
  }
}

@reflectiveTest
class VariableDeclarationListCompletionTest extends CompletionTestCase {
  Future<void> test_type_voidAfterFinal() async {
    addTestFile('''
class C {
  final ^
}
''');
    await getSuggestions();
    assertHasCompletion('void');
  }
}
