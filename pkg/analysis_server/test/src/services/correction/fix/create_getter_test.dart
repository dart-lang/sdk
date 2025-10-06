// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateGetterMixinTest);
    defineReflectiveTests(CreateGetterTest);
  });
}

@reflectiveTest
class CreateGetterMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createGetter;

  Future<void> test_dotShorthand() async {
    await resolveTestCode('''
mixin M {
}

void f() {
  M v = .test;
  print(v);
}
''');
    await assertHasFix('''
mixin M {
  static M get test => null;
}

void f() {
  M v = .test;
  print(v);
}
''');
  }

  Future<void> test_inExtensionGetter() async {
    await resolveTestCode('''
mixin M {
  void m(M m) => m.foo;
}

extension on M {
  int get foo => bar;
}
''');
    await assertHasFix('''
mixin M {
  int get bar => null;

  void m(M m) => m.foo;
}

extension on M {
  int get foo => bar;
}
''');
  }

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(M a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part of 'test.dart';

mixin M {
  int? get myUndefinedGetter => null;
}
''', target: partPath);
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

mixin M {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part 'test.dart';

mixin M {
  int? get myUndefinedGetter => null;
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

mixin M {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(M a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part of 'main.dart';

mixin M {
  int? get myUndefinedGetter => null;
}
''', target: part1Path);
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
    await assertHasFix('''
mixin M {
  int get test => null;
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
mixin M {
  void f() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
mixin M {
  int get test => null;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }
}

@reflectiveTest
class CreateGetterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createGetter;

  Future<void> test_dotShorthand_class() async {
    await resolveTestCode('''
class A {
}
void f() {
  A v = .getter;
  print(v);
}
''');
    await assertHasFix('''
class A {
  static A get getter => null;
}
void f() {
  A v = .getter;
  print(v);
}
''');
  }

  Future<void> test_dotShorthand_extensionType() async {
    await resolveTestCode('''
extension type A(int i) {
}
void f() {
  A v = .getter;
  print(v);
}
''');
    await assertHasFix('''
extension type A(int i) {
  static A get getter => null;
}
void f() {
  A v = .getter;
  print(v);
}
''');
  }

  Future<void> test_extension_type() async {
    await resolveTestCode('''
extension type A(String s) {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
extension type A(String s) {
  int get test => null;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_guard() async {
    await resolveTestCode('''
class A {
  void f(Object? x) {
    if (x case String() when getter) {}
  }
}
''');
    await assertHasFix('''
class A {
  bool get getter => null;

  void f(Object? x) {
    if (x case String() when getter) {}
  }
}
''');
  }

  Future<void> test_hint_getter() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_inExtensionGetter_class() async {
    await resolveTestCode('''
class A {
  void m(A a) => a.foo;
}

extension on A {
  int get foo => bar;
}
''');
    await assertHasFix('''
class A {
  int get bar => null;

  void m(A a) => a.foo;
}

extension on A {
  int get foo => bar;
}
''');
  }

  Future<void> test_inExtensionGetter_extensionType() async {
    await resolveTestCode('''
extension type A(int _i) {
  void m(A a) => a.foo;
}

extension on A {
  int get foo => bar;
}
''');
    await assertHasFix('''
extension type A(int _i) {
  int get bar => null;

  void m(A a) => a.foo;
}

extension on A {
  int get foo => bar;
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f(List p) {
  int v = p.foo;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
extension E on String {
  int m()  => g;
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
extension E on String {
  static int m()  => g;
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_location_afterLastGetter() async {
    await resolveTestCode('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  existingMethod() {}
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int existingField = 0;

  int get existingGetter => 0;

  int get test => null;

  existingMethod() {}
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_main_part() async {
    var partPath = join(testPackageLibPath, 'part.dart');
    newFile(partPath, '''
part of 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part 'part.dart';

void foo(A a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part of 'test.dart';

class A {
  int? get myUndefinedGetter => null;
}
''', target: partPath);
  }

  Future<void> test_multiLevel() async {
    await resolveTestCode('''
class A {
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_typed() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_untyped() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
  Object? get test => null;
}
''');
  }

  Future<void> test_objectPattern_explicitName_wildcardPattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_objectPattern_implicitName_variablePattern() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
  int get test => null;
}
''');
  }

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  int v = E(s).test;
  print(v);
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_part_main() async {
    var mainPath = join(testPackageLibPath, 'main.dart');
    newFile(mainPath, '''
part 'test.dart';

class A {
}
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part 'test.dart';

class A {
  int? get myUndefinedGetter => null;
}
''', target: mainPath);
  }

  Future<void> test_part_sibling() async {
    var part1Path = join(testPackageLibPath, 'part1.dart');
    newFile(part1Path, '''
part of 'main.dart';

class A {
}
''');
    newFile(join(testPackageLibPath, 'main.dart'), '''
part 'part1.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'main.dart';

void foo(A a) {
  int? _ = a.myUndefinedGetter;
}
''');
    await assertHasFix('''
part of 'main.dart';

class A {
  int? get myUndefinedGetter => null;
}
''', target: part1Path);
  }

  Future<void> test_qualified_instance() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int get test => null;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_qualified_instance_differentLibrary() async {
    newFile('$testPackageLibPath/other.dart', '''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
}
''');

    await resolveTestCode('''
import 'package:test/other.dart';

void f(A a) {
  int v = a.test;
  print(v);
}
''');

    await assertHasFix('''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
  int get test => null;
}
''', target: '$testPackageLibPath/other.dart');
  }

  Future<void> test_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
  get test => null;
}
''');
  }

  Future<void> test_qualified_instance_inPart_self() async {
    await resolveTestCode('''
part of 'a.dart';

class A {
}

void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_qualified_propagatedType() async {
    await resolveTestCode('''
class A {
  A get self => this;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  A get self => this;

  int get test => null;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  Future<void> test_record() async {
    await resolveTestCode('''
class A {
  (bool,) get record => (myBool,);
}
''');
    await assertHasFix('''
class A {
  (bool,) get record => (myBool,);

  bool get myBool => null;
}
''');
  }

  Future<void> test_record_named() async {
    await resolveTestCode('''
class A {
  ({int v,}) get record => (v: v,);
}
''');
    await assertHasFix('''
class A {
  ({int v,}) get record => (v: v,);

  int get v => null;
}
''');
  }

  Future<void> test_setterContext() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  a.test = 42;
}
''');
    await assertNoFix();
  }

  Future<void> test_static_class() async {
    await resolveTestCode('''
class C {
}

void f(String s) {
  int v = C.test;
  print(v);
}
''');
    await assertHasFix('''
class C {
  static int get test => null;
}

void f(String s) {
  int v = C.test;
  print(v);
}
''');
  }

  Future<void> test_static_extension() async {
    await resolveTestCode('''
extension E on String {
}

void f(String s) {
  int v = E.test;
  print(v);
}
''');
    // This should be handled by create extension member fixes
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_asInvocationArgument() async {
    await resolveTestCode('''
class A {
  void m() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix('''
class A {
  String get test => null;

  void m() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_unqualified_instance_assignmentLhs() async {
    await resolveTestCode('''
class A {
  void f() {
    test = 42;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  void f() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  int get test => null;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_unqualified_instance_asStatement() async {
    await resolveTestCode('''
class A {
  void f() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  get test => null;

  void f() {
    test;
  }
}
''');
  }
}
