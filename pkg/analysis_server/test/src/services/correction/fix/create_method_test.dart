// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingHashOrEqualsTest);
    defineReflectiveTests(CreateMethodMixinTest);
    defineReflectiveTests(CreateMethodTest);
  });
}

@reflectiveTest
class AddMissingHashOrEqualsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CREATE_METHOD;

  @override
  String get lintCode => LintNames.hash_and_equals;

  Future<void> test_equals() async {
    await resolveTestCode('''
class C {
  @override
  int get hashCode => 13;
}
''');
    await assertHasFix('''
class C {
  @override
  int get hashCode => 13;

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
}
''');
  }

  /// See: https://github.com/dart-lang/sdk/issues/43867
  Future<void> test_equals_fieldHashCode() async {
    await resolveTestCode('''
class C {
  @override
  int hashCode = 13;
}
''');
    await assertHasFix('''
class C {
  @override
  int hashCode = 13;

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
}
''');
  }

  Future<void> test_hashCode() async {
    await resolveTestCode('''
class C {
  @override
  bool operator ==(Object other) => false;
}
''');
    await assertHasFix('''
class C {
  @override
  bool operator ==(Object other) => false;

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;

}
''');
  }
}

@reflectiveTest
class CreateMethodMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_METHOD;

  Future<void> test_createQualified_instance() async {
    await resolveTestCode('''
mixin M {}

main(M m) {
  m.myUndefinedMethod();
}
''');
    await assertHasFix('''
mixin M {
  void myUndefinedMethod() {}
}

main(M m) {
  m.myUndefinedMethod();
}
''');
  }

  Future<void> test_createQualified_static() async {
    await resolveTestCode('''
mixin M {}

main() {
  M.myUndefinedMethod();
}
''');
    await assertHasFix('''
mixin M {
  static void myUndefinedMethod() {}
}

main() {
  M.myUndefinedMethod();
}
''');
  }

  Future<void> test_createUnqualified() async {
    await resolveTestCode('''
mixin M {
  main() {
    myUndefinedMethod();
  }
}
''');
    await assertHasFix('''
mixin M {
  main() {
    myUndefinedMethod();
  }

  void myUndefinedMethod() {}
}
''');
  }

  Future<void> test_functionType_method_enclosingMixin_static() async {
    await resolveTestCode('''
mixin M {
  static foo() {
    useFunction(test);
  }
}

useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
mixin M {
  static foo() {
    useFunction(test);
  }

  static int test(double a, String b) {
  }
}

useFunction(int g(double a, String b)) {}
''');
  }

  Future<void> test_functionType_method_targetMixin() async {
    await resolveTestCode('''
main(M m) {
  useFunction(m.test);
}

mixin M {
}

useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
main(M m) {
  useFunction(m.test);
}

mixin M {
  int test(double a, String b) {
  }
}

useFunction(int g(double a, String b)) {}
''');
  }
}

@reflectiveTest
class CreateMethodTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_METHOD;

  Future<void> test_createQualified_emptyClassBody() async {
    await resolveTestCode('''
class A {}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  Future<void> test_createQualified_fromClass() async {
    await resolveTestCode('''
class A {
}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  Future<void> test_createQualified_fromClass_hasOtherMember() async {
    await resolveTestCode('''
class A {
  foo() {}
}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  foo() {}

  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  Future<void> test_createQualified_fromInstance() async {
    await resolveTestCode('''
class A {
}
main(A a) {
  a.myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  void myUndefinedMethod() {}
}
main(A a) {
  a.myUndefinedMethod();
}
''');
  }

  Future<void> test_createQualified_targetIsFunctionType() async {
    await resolveTestCode('''
typedef A();
main() {
  A.myUndefinedMethod();
}
''');
    await assertNoFix();
  }

  Future<void> test_createQualified_targetIsUnresolved() async {
    await resolveTestCode('''
main() {
  NoSuchClass.myUndefinedMethod();
}
''');
    await assertNoFix();
  }

  Future<void> test_createUnqualified_duplicateArgumentNames() async {
    await resolveTestCode('''
class C {
  int x;
}

class D {
  foo(C c1, C c2) {
    bar(c1.x, c2.x);
  }
}''');
    await assertHasFix('''
class C {
  int x;
}

class D {
  foo(C c1, C c2) {
    bar(c1.x, c2.x);
  }

  void bar(int x, int x2) {}
}''');
  }

  Future<void> test_createUnqualified_parameters() async {
    await resolveTestCode('''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }

  void myUndefinedMethod(int i, double d, String s) {}
}
''');
    // linked positions
    var index = 0;
    assertLinkedGroup(
        change.linkedEditGroups[index++], ['void myUndefinedMethod(']);
    assertLinkedGroup(change.linkedEditGroups[index++],
        ['myUndefinedMethod(0', 'myUndefinedMethod(int']);
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['int i'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['int', 'num', 'Object', 'Comparable<num>']));
    assertLinkedGroup(change.linkedEditGroups[index++], ['i,']);
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['double d'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['double', 'num', 'Object', 'Comparable<num>']));
    assertLinkedGroup(change.linkedEditGroups[index++], ['d,']);
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['String s'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['String', 'Object', 'Comparable<String>', 'Pattern']));
    assertLinkedGroup(change.linkedEditGroups[index++], ['s)']);
  }

  Future<void> test_createUnqualified_parameters_named() async {
    await resolveTestCode('''
class A {
  main() {
    myUndefinedMethod(0, bbb: 1.0, ccc: '2');
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    myUndefinedMethod(0, bbb: 1.0, ccc: '2');
  }

  void myUndefinedMethod(int i, {double bbb, String ccc}) {}
}
''');
    // linked positions
    var index = 0;
    assertLinkedGroup(
        change.linkedEditGroups[index++], ['void myUndefinedMethod(']);
    assertLinkedGroup(change.linkedEditGroups[index++],
        ['myUndefinedMethod(0', 'myUndefinedMethod(int']);
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['int i'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['int', 'num', 'Object', 'Comparable<num>']));
    assertLinkedGroup(change.linkedEditGroups[index++], ['i,']);
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['double bbb'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['double', 'num', 'Object', 'Comparable<num>']));
    assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['String ccc'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['String', 'Object', 'Comparable<String>', 'Pattern']));
  }

  Future<void> test_createUnqualified_returnType() async {
    await resolveTestCode('''
class A {
  main() {
    int v = myUndefinedMethod();
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  main() {
    int v = myUndefinedMethod();
    print(v);
  }

  int myUndefinedMethod() {}
}
''');
    // linked positions
    assertLinkedGroup(change.linkedEditGroups[0], ['int myUndefinedMethod(']);
    assertLinkedGroup(change.linkedEditGroups[1],
        ['myUndefinedMethod();', 'myUndefinedMethod() {']);
  }

  Future<void> test_createUnqualified_staticFromField() async {
    await resolveTestCode('''
class A {
  static var f = myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  static var f = myUndefinedMethod();

  static myUndefinedMethod() {}
}
''');
  }

  Future<void> test_createUnqualified_staticFromMethod() async {
    await resolveTestCode('''
class A {
  static main() {
    myUndefinedMethod();
  }
}
''');
    await assertHasFix('''
class A {
  static main() {
    myUndefinedMethod();
  }

  static void myUndefinedMethod() {}
}
''');
  }

  Future<void> test_functionType_method_enclosingClass_instance() async {
    await resolveTestCode('''
class C {
  void m1() {
    m2(m3);
  }

  void m2(int Function(int) f) {}
}
''');
    await assertHasFix('''
class C {
  void m1() {
    m2(m3);
  }

  void m2(int Function(int) f) {}

  int m3(int p1) {
  }
}
''');
  }

  Future<void> test_functionType_method_enclosingClass_static() async {
    await resolveTestCode('''
class A {
  static foo() {
    useFunction(test);
  }
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
class A {
  static foo() {
    useFunction(test);
  }

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  Future<void> test_functionType_method_enclosingClass_static2() async {
    await resolveTestCode('''
class A {
  var f;
  A() : f = useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
class A {
  var f;
  A() : f = useFunction(test);

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  Future<void> test_functionType_method_targetClass() async {
    await resolveTestCode('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
main(A a) {
  useFunction(a.test);
}
class A {
  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  Future<void> test_functionType_method_targetClass_hasOtherMember() async {
    await resolveTestCode('''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix('''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}

  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  Future<void> test_functionType_notFunctionType() async {
    await resolveTestCode('''
main(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    await assertNoFix();
  }

  Future<void> test_functionType_unknownTarget() async {
    await resolveTestCode('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(g) {}
''');
    await assertNoFix();
  }

  Future<void> test_generic_argumentType() async {
    await resolveTestCode('''
class A<T> {
  B b;
  Map<int, T> items;
  main() {
    b.process(items);
  }
}

class B {
}
''');
    await assertHasFix('''
class A<T> {
  B b;
  Map<int, T> items;
  main() {
    b.process(items);
  }
}

class B {
  void process(Map items) {}
}
''');
  }

  Future<void> test_generic_literal() async {
    await resolveTestCode('''
class A {
  B b;
  List<int> items;
  main() {
    b.process(items);
  }
}

class B {}
''');
    await assertHasFix('''
class A {
  B b;
  List<int> items;
  main() {
    b.process(items);
  }
}

class B {
  void process(List<int> items) {}
}
''');
  }

  Future<void> test_generic_local() async {
    await resolveTestCode('''
class A<T> {
  List<T> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix('''
class A<T> {
  List<T> items;
  main() {
    process(items);
  }

  void process(List<T> items) {}
}
''');
  }

  Future<void> test_generic_returnType() async {
    await resolveTestCode('''
class A<T> {
  main() {
    T t = new B().compute();
    print(t);
  }
}

class B {
}
''');
    await assertHasFix('''
class A<T> {
  main() {
    T t = new B().compute();
    print(t);
  }
}

class B {
  compute() {}
}
''');
  }

  Future<void> test_hint_createQualified_fromInstance() async {
    await resolveTestCode('''
class A {
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
    await assertHasFix('''
class A {
  void myUndefinedMethod() {}
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
main() {
  List.foo();
}
''');
    await assertNoFix();
  }

  Future<void> test_internal_instance() async {
    await resolveTestCode('''
extension E on String {
  int m() => n();
}
''');
    await assertHasFix('''
extension E on String {
  int m() => n();

  n() {}
}
''');
  }

  Future<void> test_internal_static() async {
    await resolveTestCode('''
extension E on String {
  static int m() => n();
}
''');
    await assertHasFix('''
extension E on String {
  static int m() => n();

  static n() {}
}
''');
  }

  Future<void> test_override() async {
    await resolveTestCode('''
extension E on String {}

void f() {
  E('a').m();
}
''');
    await assertHasFix('''
extension E on String {
  void m() {}
}

void f() {
  E('a').m();
}
''');
  }

  Future<void> test_parameterType_differentPrefixInTargetUnit() async {
    var code2 = r'''
import 'test3.dart' as bbb;
export 'test3.dart';

class D {
}
''';

    addSource('/home/test/lib/test2.dart', code2);
    addSource('/home/test/lib/test3.dart', r'''
library test3;
class E {}
''');

    await resolveTestCode('''
import 'test2.dart' as aaa;

main(aaa.D d, aaa.E e) {
  d.foo(e);
}
''');

    await assertHasFix('''
import 'test3.dart' as bbb;
export 'test3.dart';

class D {
  void foo(bbb.E e) {}
}
''', target: '/home/test/lib/test2.dart');
  }

  Future<void> test_parameterType_inTargetUnit() async {
    addSource('/home/test/lib/test2.dart', r'''
class D {
}

class E {}
''');

    await resolveTestCode('''
import 'test2.dart' as test2;

main(test2.D d, test2.E e) {
  d.foo(e);
}
''');

    await assertHasFix('''
class D {
  void foo(E e) {}
}

class E {}
''', target: '/home/test/lib/test2.dart');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
extension E on String {}

void f() {
  E.m();
}
''');
    await assertHasFix('''
extension E on String {
  static void m() {}
}

void f() {
  E.m();
}
''');
  }

  Future<void> test_targetIsEnum() async {
    await resolveTestCode('''
enum MyEnum {A, B}
main() {
  MyEnum.foo();
}
''');
    await assertNoFix();
  }
}
