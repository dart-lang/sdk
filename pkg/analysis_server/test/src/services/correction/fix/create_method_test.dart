// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateMethodTest);
    defineReflectiveTests(CreateMethodMixinTest);
  });
}

@reflectiveTest
class CreateMethodMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_METHOD;

  test_createQualified_instance() async {
    await resolveTestUnit('''
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

  test_createQualified_static() async {
    await resolveTestUnit('''
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

  test_createUnqualified() async {
    await resolveTestUnit('''
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

  test_functionType_method_enclosingMixin_static() async {
    await resolveTestUnit('''
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

  test_functionType_method_targetMixin() async {
    await resolveTestUnit('''
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

  test_createQualified_emptyClassBody() async {
    await resolveTestUnit('''
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

  test_createQualified_fromClass() async {
    await resolveTestUnit('''
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

  test_createQualified_fromClass_hasOtherMember() async {
    await resolveTestUnit('''
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

  test_createQualified_fromInstance() async {
    await resolveTestUnit('''
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

  test_createQualified_targetIsFunctionType() async {
    await resolveTestUnit('''
typedef A();
main() {
  A.myUndefinedMethod();
}
''');
    await assertNoFix();
  }

  test_createQualified_targetIsUnresolved() async {
    await resolveTestUnit('''
main() {
  NoSuchClass.myUndefinedMethod();
}
''');
    await assertNoFix();
  }

  test_createUnqualified_duplicateArgumentNames() async {
    await resolveTestUnit('''
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

  test_createUnqualified_parameters() async {
    await resolveTestUnit('''
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
    int index = 0;
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

  test_createUnqualified_parameters_named() async {
    await resolveTestUnit('''
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
    int index = 0;
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

  test_createUnqualified_returnType() async {
    await resolveTestUnit('''
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

  test_createUnqualified_staticFromField() async {
    await resolveTestUnit('''
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

  test_createUnqualified_staticFromMethod() async {
    await resolveTestUnit('''
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

  test_functionType_method_enclosingClass_static() async {
    await resolveTestUnit('''
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

  test_functionType_method_enclosingClass_static2() async {
    await resolveTestUnit('''
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

  test_functionType_method_targetClass() async {
    await resolveTestUnit('''
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

  test_functionType_method_targetClass_hasOtherMember() async {
    await resolveTestUnit('''
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

  test_functionType_notFunctionType() async {
    await resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    await assertNoFix();
  }

  test_functionType_unknownTarget() async {
    await resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(g) {}
''');
    await assertNoFix();
  }

  test_generic_argumentType() async {
    await resolveTestUnit('''
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

  test_generic_literal() async {
    await resolveTestUnit('''
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

  test_generic_local() async {
    await resolveTestUnit('''
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

  test_generic_returnType() async {
    await resolveTestUnit('''
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

  test_hint_createQualified_fromInstance() async {
    await resolveTestUnit('''
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

  test_inSDK() async {
    await resolveTestUnit('''
main() {
  List.foo();
}
''');
    await assertNoFix();
  }

  test_parameterType_differentPrefixInTargetUnit() async {
    String code2 = r'''
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

    await resolveTestUnit('''
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

  test_parameterType_inTargetUnit() async {
    addSource('/home/test/lib/test2.dart', r'''
class D {
}

class E {}
''');

    await resolveTestUnit('''
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

  test_targetIsEnum() async {
    await resolveTestUnit('''
enum MyEnum {A, B}
main() {
  MyEnum.foo();
}
''');
    await assertNoFix();
  }
}
