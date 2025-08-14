// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToDotShorthandTest);
  });
}

@reflectiveTest
class ConvertToDotShorthandTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToDotShorthand;

  Future<void> test_chain_constructor_getter() async {
    await resolveTestCode('''
class A {
  A get getter => A.named();
  A.named();
}

A f() {
  return A.nam^ed().getter;
}
''');
    await assertHasAssist('''
class A {
  A get getter => A.named();
  A.named();
}

A f() {
  return .named().getter;
}
''');
  }

  Future<void> test_chain_constructor_method() async {
    await resolveTestCode('''
class A {
  A method() => A.named();
  A.named();
}

A f() {
  return A.nam^ed().method();
}
''');
    await assertHasAssist('''
class A {
  A method() => A.named();
  A.named();
}

A f() {
  return .named().method();
}
''');
  }

  Future<void> test_chain_getter_method() async {
    await resolveTestCode('''
class A {
  static A get staticGetter => A();
  A method() => A();
}

A f() {
  return A.static^Getter.method();
}
''');
    await assertHasAssist('''
class A {
  static A get staticGetter => A();
  A method() => A();
}

A f() {
  return .staticGetter.method();
}
''');
  }

  Future<void> test_chain_method_getter() async {
    await resolveTestCode('''
class A {
  A get getter => A();
  static A staticMethod() => A();
}

A f() {
  return A.staticM^ethod().getter;
}
''');
    await assertHasAssist('''
class A {
  A get getter => A();
  static A staticMethod() => A();
}

A f() {
  return .staticMethod().getter;
}
''');
  }

  Future<void> test_chain_method_method() async {
    await resolveTestCode('''
class A {
  A method() => A();
  static A staticMethod() => A();
}

A f() {
  return A.staticM^ethod().method();
}
''');
    await assertHasAssist('''
class A {
  A method() => A();
  static A staticMethod() => A();
}

A f() {
  return .staticMethod().method();
}
''');
  }

  Future<void> test_chain_outer_getter() async {
    await resolveTestCode('''
class A {
  A get getter => A();
  static A get staticGetter => A();
}

A f() {
  return A.staticGetter.get^ter;
}
''');
    await assertNoAssist();
  }

  Future<void> test_chain_outer_method() async {
    await resolveTestCode('''
class A {
  A method() => A();
  static A staticMethod() => A();
}

A f() {
  return A.staticMethod().meth^od();
}
''');
    await assertNoAssist();
  }

  Future<void> test_constructor_named_onNamedType() async {
    await resolveTestCode('''
class A {
  A.named();
}

A f() {
  return A^.named();
}
''');
    await assertHasAssist('''
class A {
  A.named();
}

A f() {
  return .named();
}
''');
  }

  Future<void> test_constructor_named_onSimpleIdentifier() async {
    await resolveTestCode('''
class A {
  A.named();
}

A f() {
  return A.na^med();
}
''');
    await assertHasAssist('''
class A {
  A.named();
}

A f() {
  return .named();
}
''');
  }

  Future<void> test_constructor_named_onSimpleIdentifier_typeArguments() async {
    await resolveTestCode('''
class A<T> {
  A.named();
}

A f() {
  return A^<int>.named();
}
''');
    await assertNoAssist();
  }

  Future<void> test_constructor_unnamed() async {
    await resolveTestCode('''
class A {}

A f() {
  return A^();
}
''');
    await assertHasAssist('''
class A {}

A f() {
  return .new();
}
''');
  }

  Future<void> test_constructor_unnamed_typeArguments() async {
    await resolveTestCode('''
class A<T> {}

A f() {
  return A^<int>();
}
''');
    await assertNoAssist();
  }

  Future<void> test_constructorReference_onNamedType() async {
    await resolveTestCode('''
Object f() {
  return Object^.new;
}
''');
    await assertHasAssist('''
Object f() {
  return .new;
}
''');
  }

  Future<void> test_constructorReference_onSimpleIdentifier() async {
    await resolveTestCode('''
Object f() {
  return Object.n^ew;
}
''');
    await assertHasAssist('''
Object f() {
  return .new;
}
''');
  }

  Future<void> test_importPrefix_chain() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A method() => A();
  A get getter => A();
  A.named();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A.named().method().ge^tter;
}
''');
    await assertNoAssist();
  }

  Future<void> test_importPrefix_constructor_onConstructor() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.named();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A.na^med();
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .named();
}
''');
  }

  Future<void> test_importPrefix_constructor_onPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.named();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefi^x.A.named();
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .named();
}
''');
  }

  Future<void> test_importPrefix_constructor_onType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A.named();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A^.named();
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .named();
}
''');
  }

  Future<void> test_importPrefix_getter_onPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A get getter => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return pref^ix.A.getter;
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .getter;
}
''');
  }

  Future<void> test_importPrefix_getter_onSimpleIdentifier() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A get getter => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A.get^ter;
}
''');
    await assertNoAssist();
  }

  Future<void> test_importPrefix_getter_onType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A get getter => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A^.getter;
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .getter;
}
''');
  }

  Future<void> test_importPrefix_method_onMethodInvocation() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A method() => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A.m^ethod();
}
''');
    await assertNoAssist();
  }

  Future<void> test_importPrefix_method_onPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A method() => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return pre^fix.A.method();
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .method();
}
''');
  }

  Future<void> test_importPrefix_method_onType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  static A method() => A();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

prefix.A f() {
  return prefix.A^.method();
}
''');
    await assertHasAssist('''
import 'a.dart' as prefix;

prefix.A f() {
  return .method();
}
''');
  }

  Future<void> test_methodInvocation_class_onNamedType() async {
    await resolveTestCode('''
class C {
  static C method() => C();
}

C f() {
  return C^.method();
}
''');
    await assertHasAssist('''
class C {
  static C method() => C();
}

C f() {
  return .method();
}
''');
  }

  Future<void> test_methodInvocation_class_onNamedType_typeArguments() async {
    await resolveTestCode('''
class C {
  static C method<T>(T t) {
    print(t);
    return C();
  }
}

C f() {
  return C^.method<int>(1);
}
''');
    await assertHasAssist('''
class C {
  static C method<T>(T t) {
    print(t);
    return C();
  }
}

C f() {
  return .method<int>(1);
}
''');
  }

  Future<void> test_methodInvocation_class_onSimpleIdentifier() async {
    await resolveTestCode('''
class C {
  static C method() => C();
}

C f() {
  return C.^method();
}
''');
    await assertHasAssist('''
class C {
  static C method() => C();
}

C f() {
  return .method();
}
''');
  }

  Future<void>
  test_methodInvocation_class_onSimpleIdentifier_typeArguments() async {
    await resolveTestCode('''
class C {
  static C method<T>(T t) {
    print(t);
    return C();
  }
}

C f() {
  return C.meth^od<int>(1);
}
''');
    await assertHasAssist('''
class C {
  static C method<T>(T t) {
    print(t);
    return C();
  }
}

C f() {
  return .method<int>(1);
}
''');
  }

  Future<void> test_methodInvocation_extensionType_onNamedType() async {
    await resolveTestCode('''
extension type C(int x) {
  static C method() => C(1);
}

C f() {
  return C^.method();
}
''');
    await assertHasAssist('''
extension type C(int x) {
  static C method() => C(1);
}

C f() {
  return .method();
}
''');
  }

  Future<void> test_methodInvocation_extensionType_onSimpleIdentifier() async {
    await resolveTestCode('''
extension type C(int x) {
  static C method() => C(1);
}

C f() {
  return C.^method();
}
''');
    await assertHasAssist('''
extension type C(int x) {
  static C method() => C(1);
}

C f() {
  return .method();
}
''');
  }

  Future<void> test_prefixedIdentifier_class_field_onNamedType() async {
    await resolveTestCode('''
class C {
  static C? field;
}

C? f() {
  return C^.field;
}
''');
    await assertHasAssist('''
class C {
  static C? field;
}

C? f() {
  return .field;
}
''');
  }

  Future<void> test_prefixedIdentifier_class_field_onSimpleIdentifier() async {
    await resolveTestCode('''
class C {
  static C? field;
}

C? f() {
  return C.fi^eld;
}
''');
    await assertHasAssist('''
class C {
  static C? field;
}

C? f() {
  return .field;
}
''');
  }

  Future<void> test_prefixedIdentifier_class_getter_onNamedType() async {
    await resolveTestCode('''
class C {
  static C get getter => C();
}

C f() {
  return C^.getter;
}
''');
    await assertHasAssist('''
class C {
  static C get getter => C();
}

C f() {
  return .getter;
}
''');
  }

  Future<void>
  test_prefixedIdentifier_class_getter_onNamedType_otherClass() async {
    await resolveTestCode('''
class A {}

class B {
  static A get getter => A();
}

A f() {
  return B^.getter;
}

''');
    await assertNoAssist();
  }

  Future<void> test_prefixedIdentifier_class_getter_onSimpleIdentifier() async {
    await resolveTestCode('''
class C {
  static C get getter => C();
}

C f() {
  return C.get^ter;
}
''');
    await assertHasAssist('''
class C {
  static C get getter => C();
}

C f() {
  return .getter;
}
''');
  }

  Future<void>
  test_prefixedIdentifier_class_getter_onSimpleIdentifier_otherClass() async {
    await resolveTestCode('''
class A {}

class B {
  static A get getter => A();
}

A f() {
  return B.g^etter;
}

''');
    await assertNoAssist();
  }

  Future<void> test_prefixedIdentifier_enum_onNamedType() async {
    await resolveTestCode('''
enum E { a }

E f() {
  return E^.a;
}
''');
    await assertHasAssist('''
enum E { a }

E f() {
  return .a;
}
''');
  }

  Future<void> test_prefixedIdentifier_enum_onSimpleIdentifier() async {
    await resolveTestCode('''
enum E { a }

E f() {
  return E.a^;
}
''');
    await assertHasAssist('''
enum E { a }

E f() {
  return .a;
}
''');
  }
}
