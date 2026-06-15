// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../src/dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

// TODO(srawlins): Figure out what to do with the rest of these tests.
//  The names do not correspond to diagnostic codes, so it isn't clear what
//  they're testing.
@reflectiveTest
class StaticTypeWarningCodeTest extends PubPackageResolutionTest {
  test_await_flattened() async {
    await resolveTestCodeWithDiagnostics('''
external Future<Future<int>> ffi();
f() async {
  Future<int> b = await ffi();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
  }

  test_await_simple() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> fi() => Future.value(0);
f() async {
  String a = await fi(); // Warning: int not assignable to String
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//           ^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  test_awaitForIn_declaredVariableRightType() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<int> stream) async {
  await for (int i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_awaitForIn_declaredVariableWrongType() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<String> stream) async {
  await for (int i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                    ^^^^^^
// [diag.forInOfInvalidElementType] The type 'Stream<String>' used in the 'for' loop must implement 'Stream' with a type argument that can be assigned to 'int'.
}
''');
  }

  test_awaitForIn_downcast() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<num> stream) async {
  await for (int i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                    ^^^^^^
// [diag.forInOfInvalidElementType] The type 'Stream<num>' used in the 'for' loop must implement 'Stream' with a type argument that can be assigned to 'int'.
}
''');
  }

  test_awaitForIn_dynamicVariable() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<int> stream) async {
  await for (var i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_awaitForIn_existingVariableRightType() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<int> stream) async {
  late int i;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  await for (i in stream) {}
}
''');
  }

  test_awaitForIn_existingVariableWrongType() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<String> stream) async {
  late int i;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  await for (i in stream) {}
//                ^^^^^^
// [diag.forInOfInvalidElementType] The type 'Stream<String>' used in the 'for' loop must implement 'Stream' with a type argument that can be assigned to 'int'.
}
''');
  }

  test_awaitForIn_streamOfDynamic() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream stream) async {
  await for (int i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_awaitForIn_upcast() async {
    await resolveTestCodeWithDiagnostics('''
f(Stream<int> stream) async {
  await for (num i in stream) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_bug21912() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);
typedef B AToB(A x);
typedef A BToA(B x);

void f(
  Function2<Function2<A, B>, Function2<B, A>> t1,
  Function2<AToB, BToA> t2
) {
  {
    Function2<Function2<int, double>, Function2<int, double>> left;
//                                                            ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'left' isn't used.

    left = t1;
//         ^^
// [diag.invalidAssignment] A value of type 'Function2<Function2<A, B>, Function2<B, A>>' can't be assigned to a variable of type 'Function2<Function2<int, double>, Function2<int, double>>'.
    left = t2;
//         ^^
// [diag.invalidAssignment] A value of type 'Function2<AToB, BToA>' can't be assigned to a variable of type 'Function2<Function2<int, double>, Function2<int, double>>'.
  }
}
''');
  }

  test_forIn_declaredVariableRightType() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int i in <int>[]) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_declaredVariableWrongType() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int i in <String>[]) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//              ^^^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'List<String>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'int'.
}
''');
  }

  test_forIn_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  dynamic d; // Could be [].
  for (var i in d) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_dynamicIterable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  dynamic iterable;
  for (int i in iterable) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_dynamicVariable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (var i in <int>[]) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_existingVariableRightType() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  for (i in <int>[]) {}
}
''');
  }

  test_forIn_existingVariableWrongType() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  for (i in <String>[]) {}
//          ^^^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'List<String>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'int'.
}
''');
  }

  test_forIn_iterableOfDynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int i in []) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_object() async {
    await resolveTestCodeWithDiagnostics('''
f(List o) { // Could be [].
  for (var i in o) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_forIn_typeBoundBad() async {
    await resolveTestCodeWithDiagnostics('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                   ^^^^^^^^
// [diag.forInOfInvalidElementType] The type 'Iterable<int>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'String'.
  }
}
''');
  }

  test_forIn_typeBoundGood() async {
    await resolveTestCodeWithDiagnostics('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (var i in iterable) {}
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  }
}
''');
  }

  test_forIn_upcast() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (num i in <int>[]) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
}
''');
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_mutated() async {
    await resolveTestCodeWithDiagnostics(r'''
callMe(f()) { f(); }
f(Object p) {
  (p is String) && callMe(() { p.length; });
//                               ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
  p = 0;
}
''');
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInLeft() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object p) {
  ((p is String) && ((p = 42) == 42)) && p.length != 0;
//                                         ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
}
''');
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInRight() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object p) {
  (p is String) && (((p = 42) == 42) && p.length != 0);
//                                        ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
}
''');
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_after() async {
    await resolveTestCodeWithDiagnostics(r'''
callMe(f()) { f(); }
g(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
//                            ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
  p = 42;
}
''');
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_before() async {
    await resolveTestCodeWithDiagnostics(r'''
callMe(f()) { f(); }
g(Object p) {
  p = 42;
  p is String ? callMe(() { p.length; }) : 0;
//                            ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
}
''');
  }

  test_typePromotion_if_accessedInClosure_hasAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
callMe(f()) { f(); }
f(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
//      ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
    });
  }
  p = 0;
}
''');
  }

  test_typePromotion_if_extends_notMoreSpecific_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
//    ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'A<V>'.
  }
}
''');
  }

  test_typePromotion_if_extends_notMoreSpecific_notMoreSpecificTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

f(A<V> p) {
  if (p is B<int>) {
    p.b;
//    ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'A<V>'.
  }
}
''');
  }

  test_typePromotion_if_hasAssignment_before() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object p) {
  if (p is String) {
    p = 0;
    p.length;
//    ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
  }
}
''');
  }

  test_typePromotion_if_hasAssignment_inClosure_anonymous_before() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object p) {
  () {p = 0;};
  if (p is String) {
    p.length;
//    ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
  }
}
''');
  }

  test_typePromotion_if_hasAssignment_inClosure_function_before() async {
    await resolveTestCodeWithDiagnostics(r'''
g(Object p) {
  f() {p = 0;};
//^
// [diag.unusedElement] The declaration 'f' isn't referenced.
  if (p is String) {
    p.length;
//    ^^^^^^
// [diag.undefinedGetter] The getter 'length' isn't defined for the type 'Object'.
  }
}
''');
  }

  test_typePromotion_if_implements_notMoreSpecific_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
//    ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'A<V>'.
  }
}
''');
  }

  test_typePromotion_if_with_notMoreSpecific_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class V {}
mixin A<T> {}
class B<S> extends Object with A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
//    ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'A<V>'.
  }
}
''');
  }

  test_wrongNumberOfTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<E> {
  late E element;
}
g(A<NoSuchType> a) {
//  ^^^^^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'NoSuchType' isn't a type, so it can't be used as a type argument.
  a.element.anyGetterExistsInDynamic;
}
''');
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest extends PubPackageResolutionTest {
  test_legalAsyncGeneratorReturnType_function_supertypeOfStream() async {
    await resolveTestCodeWithDiagnostics('''
f() async* { yield 42; }
dynamic f2() async* { yield 42; }
Object f3() async* { yield 42; }
Stream f4() async* { yield 42; }
Stream<dynamic> f5() async* { yield 42; }
Stream<Object> f6() async* { yield 42; }
Stream<num> f7() async* { yield 42; }
Stream<int> f8() async* { yield 42; }
''');
  }

  test_legalAsyncReturnType_function_supertypeOfFuture() async {
    await resolveTestCodeWithDiagnostics('''
f() async { return 42; }
dynamic f2() async { return 42; }
Object f3() async { return 42; }
Future f4() async { return 42; }
Future<dynamic> f5() async { return 42; }
Future<Object> f6() async { return 42; }
Future<num> f7() async { return 42; }
Future<int> f8() async { return 42; }
''');
  }

  test_legalSyncGeneratorReturnType_function_supertypeOfIterable() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* { yield 42; }
dynamic f2() sync* { yield 42; }
Object f3() sync* { yield 42; }
Iterable f4() sync* { yield 42; }
Iterable<dynamic> f5() sync* { yield 42; }
Iterable<Object> f6() sync* { yield 42; }
Iterable<num> f7() sync* { yield 42; }
Iterable<int> f8() sync* { yield 42; }
''');
  }
}
