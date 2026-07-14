// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';
import '../../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferredTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InferredTypeTest extends PubPackageResolutionTest {
  test_asyncClosureReturnType_flatten() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Future<int> futureInt = null;
//                      ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Future<int>'.
var f = () => futureInt;
var g = () async => futureInt;
''');
    var futureInt = result.libraryElement.topLevelVariables[0];
    expect(futureInt.name, 'futureInt');
    _assertTypeStr(futureInt.type, 'Future<int>');
    var f = result.libraryElement.topLevelVariables[1];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'Future<int> Function()');
    var g = result.libraryElement.topLevelVariables[2];
    expect(g.name, 'g');
    _assertTypeStr(g.type, 'Future<int> Function()');
  }

  test_asyncClosureReturnType_future() async {
    var result = await resolveTestCodeWithDiagnostics('''
var f = () async => 0;
''');
    var f = result.libraryElement.topLevelVariables[0];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'Future<int> Function()');
  }

  test_asyncClosureReturnType_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
FutureOr<int> futureOrInt = null;
//                          ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'FutureOr<int>'.
var f = () => futureOrInt;
var g = () async => futureOrInt;
''');
    var futureOrInt = result.libraryElement.topLevelVariables[0];
    expect(futureOrInt.name, 'futureOrInt');
    _assertTypeStr(futureOrInt.type, 'FutureOr<int>');
    var f = result.libraryElement.topLevelVariables[1];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'FutureOr<int> Function()');
    var g = result.libraryElement.topLevelVariables[2];
    expect(g.name, 'g');
    _assertTypeStr(g.type, 'Future<int> Function()');
  }

  test_blockBodiedLambdas_async_allReturnsAreFutures() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return new Future<double>.value(2.0);
    }
  };
  Future<num> g = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  Future<int> h = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                ^^^
// [diag.invalidAssignment] A value of type 'Future<num>' can't be assigned to a variable of type 'Future<int>'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_async_allReturnsAreValues() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return 1;
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  Future<int> h = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                ^^^
// [diag.invalidAssignment] A value of type 'Future<num>' can't be assigned to a variable of type 'Future<int>'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_async_mixOfValuesAndFutures() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  Future<int> h = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                ^^^
// [diag.invalidAssignment] A value of type 'Future<num>' can't be assigned to a variable of type 'Future<int>'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_asyncStar() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var f = () async* {
    yield 1;
    Stream<double> s;
    yield* s;
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 's' must be assigned before it can be used.
  };
  Stream<num> g = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  Stream<int> h = f();
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                ^^^
// [diag.invalidAssignment] A value of type 'Stream<num>' can't be assigned to a variable of type 'Stream<int>'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Stream<num> Function()');
  }

  test_blockBodiedLambdas_basic() async {
    await resolveTestCodeWithDiagnostics(r'''
test1() {
  List<int> o;
  var y = o.map((x) { return x + 1; });
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  Iterable<int> z = y;
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  String f() => null;
//              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'String'.
  var g = f;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  g = () { return 1; };
//                ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
}
''');

    var g = result.findElement.localVar('g');
    _assertTypeStr(g.type, 'String Function()');
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
String f() => null;
//            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'String'.
var g = f;
''');
    var g = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(g.type, 'String Function()');
  }

  test_blockBodiedLambdas_inferBottom_async() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() async {
  var f = () async { return null; };
  Future y = f();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  Future<String> z = f();
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                   ^^^
// [diag.invalidAssignment] A value of type 'Future<Null>' can't be assigned to a variable of type 'Future<String>'.
  String s = await f();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'String'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<Null> Function()');
  }

  test_blockBodiedLambdas_inferBottom_asyncStar() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() async {
  var f = () async* { yield null; };
  Stream y = f();
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  Stream<String> z = f();
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                   ^^^
// [diag.invalidAssignment] A value of type 'Stream<Null>' can't be assigned to a variable of type 'Stream<String>'.
  String s = await f().first;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
//           ^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'String'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Stream<Null> Function()');
  }

  test_blockBodiedLambdas_inferBottom_sync() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var h = null;
void foo(int g(Object _)) {}

main() {
  var f = (Object x) { return null; };
  String y = f(42);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//           ^^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'String'.

  f = (x) => 'hello';
//           ^^^^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'String' isn't returnable from a 'Null' function, as required by the closure's context.

  foo((x) { return null; });
//                 ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'int' function, as required by the closure's context.
  foo((x) { throw "not implemented"; });
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Null Function(Object)');
  }

  test_blockBodiedLambdas_inferBottom_syncStar() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var f = () sync* { yield null; };
  Iterable y = f();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  Iterable<String> z = f();
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                     ^^^
// [diag.invalidAssignment] A value of type 'Iterable<Null>' can't be assigned to a variable of type 'Iterable<String>'.
  String s = f().first;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'String'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Iterable<Null> Function()');
  }

  test_blockBodiedLambdas_LUB() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' show Random;
test2() {
  List<num> o;
  var y = o.map((x) {
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
    if (new Random().nextBool()) {
      return x.toInt() + 1;
    } else {
      return x.toDouble();
    }
  });
  Iterable<num> w = y;
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'w' isn't used.
  Iterable<int> z = y;
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                  ^
// [diag.invalidAssignment] A value of type 'Iterable<num>' can't be assigned to a variable of type 'Iterable<int>'.
}
''');
  }

  test_blockBodiedLambdas_nestedLambdas() async {
    // Original feature request: https://github.com/dart-lang/sdk/issues/25487
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var f = () {
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'f' isn't used.
    return (int x) { return 2.0 * x; };
  };
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'double Function(int) Function()');
  }

  test_blockBodiedLambdas_noReturn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test1() {
  List<int> o;
  var y = o.map((x) { });
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  Iterable<int> z = y;
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                  ^
// [diag.invalidAssignment] A value of type 'Iterable<Null>' can't be assigned to a variable of type 'Iterable<int>'.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'Iterable<Null>');
  }

  test_blockBodiedLambdas_syncStar() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var f = () sync* {
    yield 1;
    yield* [3, 4.0];
  };
  Iterable<num> g = f();
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'g' isn't used.
  Iterable<int> h = f();
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'h' isn't used.
//                  ^^^
// [diag.invalidAssignment] A value of type 'Iterable<num>' can't be assigned to a variable of type 'Iterable<int>'.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Iterable<num> Function()');
  }

  test_bottom() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = null;
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'dynamic');
  }

  test_bottom_inClosure() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = () => null;
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'Null Function()');
  }

  test_circularReference_viaClosures() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = () => y;
//  ^
// [diag.topLevelCycle] The type of 'x' can't be inferred because it depends on itself through the cycle: x, y.
var y = () => x;
//  ^
// [diag.topLevelCycle] The type of 'y' can't be inferred because it depends on itself through the cycle: x, y.
''');

    var x = result.libraryElement.topLevelVariables[0];
    var y = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'dynamic');
  }

  test_circularReference_viaClosures_initializerTypes() async {
    var result = await resolveTestCodeWithDiagnostics('''
var x = () => y;
//  ^
// [diag.topLevelCycle] The type of 'x' can't be inferred because it depends on itself through the cycle: x, y.
var y = () => x;
//  ^
// [diag.topLevelCycle] The type of 'y' can't be inferred because it depends on itself through the cycle: x, y.
''');

    var x = result.libraryElement.topLevelVariables[0];
    var y = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'dynamic');
  }

  test_conflictsCanHappen2() async {
    await resolveTestCodeWithDiagnostics('''
class I1 {
  int x;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'x' must be initialized.
}
class I2 {
  int y;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'y' must be initialized.
}

class I3 implements I1, I2 {
  int x;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'x' must be initialized.
  int y;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'y' must be initialized.
}

class A {
  final I1 a = null;
//         ^
// [context 1] The member being overridden.
//             ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'I1'.
}

class B {
  final I2 a = null;
//         ^
// [context 2] The member being overridden.
//             ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'I2'.
}

class C1 implements A, B {
  I3 get a => null;
//            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'a' because it has a return type of 'I3'.
}

class C2 implements A, B {
  get a => null;
//    ^
// [diag.invalidOverride][context 1] 'C2.a' ('dynamic Function()') isn't a valid override of 'A.a' ('I1 Function()').
// [diag.invalidOverride][context 2] 'C2.a' ('dynamic Function()') isn't a valid override of 'B.a' ('I2 Function()').
}
''');
  }

  test_constructors_downwardsWithConstraint() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26431
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
class Foo<T extends A> {}
void main() {
  Foo<B> foo = new Foo();
//       ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
  }

  test_constructors_inferFromArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;
  C(this.t);
}

main() {
  var x = new C(42);

  num y;
  C<int> c_int = new C(y);
//       ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'c_int' isn't used.
//                     ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'y' must be assigned before it can be used.
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = new C(123);
//       ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'c_num' isn't used.
  C<num> c_num2 = (new C(456))
//       ^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'c_num2' isn't used.
      ..t = 1.0;

  // Don't infer from explicit dynamic.
  var c_dynamic = new C<dynamic>(42);
//    ^^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'c_dynamic' isn't used.
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    _assertTypeStr(result.findElement.localVar('x').type, 'C<int>');
    _assertTypeStr(result.findElement.localVar('c_int').type, 'C<int>');
    _assertTypeStr(result.findElement.localVar('c_num').type, 'C<num>');
    _assertTypeStr(result.findElement.localVar('c_dynamic').type, 'C<dynamic>');
  }

  test_constructors_inferFromArguments_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final T t;
  const C(this.t);
}

main() {
  var x = const C(42);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_constWithUpperBound() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26993
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends num> {
  final T x;
  const C(this.x);
}
class D<T extends num> {
  const D();
}
void f() {
  const c = const C(0);
  C<int> c2 = c;
//       ^^
// [diag.unusedLocalVariable] The value of the local variable 'c2' isn't used.
  const D<int> d = const D();
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'd' isn't used.
}
''');
  }

  test_constructors_inferFromArguments_downwardsFromConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> { C(List<T> list); }

main() {
  var x = new C([123]);
  C<int> y = x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.

  var a = new C<dynamic>([123]);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  // This one however works.
  var b = new C<Object>([123]);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
  }

  test_constructors_inferFromArguments_factory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;

  C._();
//^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 't' must be initialized.

  factory C(T t) {
    var c = new C<T>._();
    c.t = t;
    return c;
  }
}


main() {
  var x = new C(42);
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_factory_callsConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A<T> f = new A();
  A();
  factory A.factory() => new A();
  A<T> m() => new A();
}
''');
  }

  test_constructors_inferFromArguments_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;
  C.named(List<T> t);
//^^^^^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 't' must be initialized.
}


main() {
  var x = new C.named(<int>[]);
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_namedFactory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;
  C();
//^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 't' must be initialized.

  factory C.named(T t) {
    var c = new C<T>();
    c.t = t;
    return c;
  }
}


main() {
  var x = new C.named(42);
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_redirecting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  T t;
  C(this.t);
  C.named(List<T> t) : this(t[0]);
}


main() {
  var x = new C.named(<int>[42]);
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_redirectingFactory() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C<T> {
  T get t;
  void set t(T t);

  factory C(T t) = CImpl<T>;
}

class CImpl<T> implements C<T> {
  T t;
  CImpl(this.t);
}

main() {
  var x = new C(42);
  x.t = 'hello';
//      ^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_reverseTypeParameters() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26990
    await resolveTestCodeWithDiagnostics('''
class Pair<T, U> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair<U, T> get reversed => new Pair(u, t);
}
''');
  }

  test_constructors_tooManyPositionalArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
main() {
  var a = new A(42);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//              ^^
// [diag.extraPositionalArguments] Too many positional arguments: 0 expected, but 1 found.
}
''');

    var a = result.findElement.localVar('a');
    _assertTypeStr(a.type, 'A<dynamic>');
  }

  test_doNotInferOverriddenFieldsThatExplicitlySayDynamic_infer() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  final int x = 2;
//          ^
// [context 1] The member being overridden.
}

class B implements A {
  dynamic get x => 3;
//            ^
// [diag.invalidOverride][context 1] 'B.x' ('dynamic Function()') isn't a valid override of 'A.x' ('int Function()').
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_dontInferFieldTypeWhenInitializerIsNull() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = null;
var y = 3;
class A {
  static var x = null;
  static var y = 3;

  var x2 = null;
  var y2 = 3;
}

test() {
  x = "hi";
  y = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  A.x = "hi";
  A.y = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  new A().x2 = "hi";
  new A().y2 = "hi";
//             ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_dontInferTypeOnDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
test() {
  dynamic x = 3;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = "hi";
}
''');
  }

  test_dontInferTypeWhenInitializerIsNull() async {
    await resolveTestCodeWithDiagnostics(r'''
test() {
  var x = null;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = "hi";
  x = 3;
}
''');
  }

  test_downwardInference_miscellaneous() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T Function2<S, T>(S x);
class A<T> {
  Function2<T, T> x;
  A(this.x);
}
void main() {
  {  // Variables, nested literals
    var x = "hello";
    var y = 3;
    void f(List<Map<int, String>> l) {};
    f([{y: x}]);
  }
  {
    int f(int x) => 0;
    A<int> a = new A(f);
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');
  }

  test_downwardsInference_insideTopLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  B<int> b;
//       ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'b' must be initialized.
}

class B<T> {
  B(T x);
}

var t1 = new A()..b = new B(1);
var t2 = <B<int>>[new B(2)];
var t3 = [
            new B(3)
         ];
''');
  }

  test_downwardsInferenceAnnotations() async {
    await resolveTestCodeWithDiagnostics('''
class Foo {
  const Foo(List<String> l);
  const Foo.named(List<String> l);
}
@Foo(const [])
class Bar {}
@Foo.named(const [])
class Baz {}
''');
  }

  test_downwardsInferenceAssignmentStatements() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  List<int> l;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'l' isn't used.
  l = ["hello"];
//     ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  l = (l = [1]);
}
''');
  }

  test_downwardsInferenceAsyncAwait() async {
    await resolveTestCodeWithDiagnostics(r'''
Future test() async {
  dynamic d;
  List<int> l0 = await [d];
//          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
  List<int> l1 = await new Future.value([d]);
//          ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
}
''');
  }

  test_downwardsInferenceForEach() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}

Future main() async {
  for(int x in [1, 2, 3]) {}
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  await for(int x in new MyStream()) {}
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');
  }

  test_downwardsInferenceInitializingFormalDefaultFormal() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T Function2<S, T>([S x]);
class Foo {
  List<int> x;
  Foo([this.x = const [1]]);
  Foo.named([List<int> x = const [1]]);
//^^^^^^^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'x' must be initialized.
}
void f([List<int> l = const [1]]) {}
// We do this inference in an early task but don't preserve the infos.
Function2<List<int>, String> g = ([llll = const [1]]) => "hello";
''');
  }

  test_downwardsInferenceOnConstructorArguments_inferDownwards() async {
    await resolveTestCodeWithDiagnostics(r'''
class F0 {
  F0(List<int> a) {}
}
class F1 {
  F1({List<int> a}) {}
//              ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class F2 {
  F2(Iterable<int> a) {}
}
class F3 {
  F3(Iterable<Iterable<int>> a) {}
}
class F4 {
  F4({Iterable<Iterable<int>> a}) {}
//                            ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
void main() {
  new F0([]);
  new F0([3]);
  new F0(["hello"]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F0(["hello", 3]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F1(a: []);
  new F1(a: [3]);
  new F1(a: ["hello"]);
//           ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F1(a: ["hello", 3]);
//           ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F2([]);
  new F2([3]);
  new F2(["hello"]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F2(["hello", 3]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F3([]);
  new F3([[3]]);
  new F3([["hello"]]);
//         ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F3([["hello"], [3]]);
//         ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F4(a: []);
  new F4(a: [[3]]);
  new F4(a: [["hello"]]);
//            ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F4(a: [["hello"], [3]]);
//            ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
}
''');
  }

  test_downwardsInferenceOnFunctionArguments_inferDownwards() async {
    await resolveTestCodeWithDiagnostics(r'''
void f0(List<int> a) {}
void f1({List<int> a}) {}
//                 ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
void f2(Iterable<int> a) {}
void f3(Iterable<Iterable<int>> a) {}
void f4({Iterable<Iterable<int>> a}) {}
//                               ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
void main() {
  f0([]);
  f0([3]);
  f0(["hello"]);
//    ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  f0(["hello", 3]);
//    ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  f1(a: []);
  f1(a: [3]);
  f1(a: ["hello"]);
//       ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  f1(a: ["hello", 3]);
//       ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  f2([]);
  f2([3]);
  f2(["hello"]);
//    ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  f2(["hello", 3]);
//    ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  f3([]);
  f3([[3]]);
  f3([["hello"]]);
//     ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  f3([["hello"], [3]]);
//     ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  f4(a: []);
  f4(a: [[3]]);
  f4(a: [["hello"]]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  f4(a: [["hello"], [3]]);
//        ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
}
''');
  }

  test_downwardsInferenceOnFunctionExpressions() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T Function2<S, T>(S x);

void main () {
  {
    Function2<int, String> l0 = (int x) => null;
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                                         ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l1 = (int x) => "hello";
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Function2<int, String> l2 = (String x) => "hello";
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                              ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String Function(String)' can't be assigned to a variable of type 'Function2<int, String>'.
    Function2<int, String> l3 = (int x) => 3;
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                         ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l4 = (int x) {return 3;};
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                              ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
  }
  {
    Function2<int, String> l0 = (x) => null;
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                                     ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l1 = (x) => "hello";
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Function2<int, String> l2 = (x) => 3;
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                     ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l3 = (x) {return 3;};
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                          ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l4 = (x) {return x;};
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                          ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
  }
  {
    Function2<int, List<String>> l0 = (int x) => null;
//                               ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                                               ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'List<String>' function, as required by the closure's context.
    Function2<int, List<String>> l1 = (int x) => ["hello"];
//                               ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Function2<int, List<String>> l2 = (String x) => ["hello"];
//                               ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<String> Function(String)' can't be assigned to a variable of type 'Function2<int, List<String>>'.
    Function2<int, List<String>> l3 = (int x) => [3];
//                               ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                                ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
    Function2<int, List<String>> l4 = (int x) {return [3];};
//                               ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
//                                                     ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
  }
  {
    Function2<int, int> l0 = (x) => x;
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    Function2<int, int> l1 = (x) => x+1;
//                      ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Function2<int, String> l2 = (x) => x;
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                                     ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    Function2<int, String> l3 = (x) => x.substring(3);
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                       ^^^^^^^^^
// [diag.undefinedMethod] The method 'substring' isn't defined for the type 'int'.
    Function2<String, String> l4 = (x) => x.substring(3);
//                            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
  }
}
''');
  }

  test_downwardsInferenceOnFunctionOfTUsingTheT() async {
    await resolveTestCodeWithDiagnostics(r'''
void main () {
  {
    T f<T>(T x) => null;
//                 ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
    var v1 = f;
//      ^^
// [diag.unusedLocalVariable] The value of the local variable 'v1' isn't used.
    v1 = <S>(x) => x;
  }
  {
    List<T> f<T>(T x) => null;
//                       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'List<T>'.
    var v2 = f;
    v2 = <S>(x) => [x];
    Iterable<int> r = v2(42);
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'r' isn't used.
    Iterable<String> s = v2('hello');
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
    Iterable<List<int>> t = v2(<int>[]);
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 't' isn't used.
    Iterable<num> u = v2(42);
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'u' isn't used.
    Iterable<num> v = v2<num>(42);
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  }
}
''');
  }

  test_downwardsInferenceOnGenericConstructorArguments_emptyList() async {
    await resolveTestCodeWithDiagnostics(r'''
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
//                          ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
void main() {
  new F3([]);
  new F4(a: []);
}
''');
  }

  test_downwardsInferenceOnGenericConstructorArguments_inferDownwards() async {
    await resolveTestCodeWithDiagnostics(r'''
class F0<T> {
  F0(List<T> a) {}
}
class F1<T> {
  F1({List<T> a}) {}
//            ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class F2<T> {
  F2(Iterable<T> a) {}
}
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
//                          ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}
class F5<T> {
  F5(Iterable<Iterable<Iterable<T>>> a) {}
}
void main() {
  new F0<int>([]);
  new F0<int>([3]);
  new F0<int>(["hello"]);
//             ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F0<int>(["hello", 3]);
//             ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F1<int>(a: []);
  new F1<int>(a: [3]);
  new F1<int>(a: ["hello"]);
//                ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F1<int>(a: ["hello", 3]);
//                ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F2<int>([]);
  new F2<int>([3]);
  new F2<int>(["hello"]);
//             ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F2<int>(["hello", 3]);
//             ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F3<int>([]);
  new F3<int>([[3]]);
  new F3<int>([["hello"]]);
//              ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F3<int>([["hello"], [3]]);
//              ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F4<int>(a: []);
  new F4<int>(a: [[3]]);
  new F4<int>(a: [["hello"]]);
//                 ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  new F4<int>(a: [["hello"], [3]]);
//                 ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.

  new F3([]);
  var f31 = new F3([[3]]);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'f31' isn't used.
  var f32 = new F3([["hello"]]);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'f32' isn't used.
  var f33 = new F3([["hello"], [3]]);
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'f33' isn't used.

  new F4(a: []);
  new F4(a: [[3]]);
  new F4(a: [["hello"]]);
  new F4(a: [["hello"], [3]]);

  new F5([[[3]]]);
}
''');
  }

  test_downwardsInferenceOnGenericFunctionExpressions() async {
    await resolveTestCodeWithDiagnostics(r'''
void main () {
  {
    String f<S>(int x) => null;
//                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'String'.
    var v = f;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    v = <T>(int x) => null;
//                    ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
    v = <T>(int x) => "hello";
    v = <T>(String x) => "hello";
//      ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String Function<T>(String)' can't be assigned to a variable of type 'String Function<S>(int)'.
    v = <T>(int x) => 3;
//                    ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    v = <T>(int x) {return 3;};
//                         ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
  }
  {
    String f<S>(int x) => null;
//                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'String'.
    var v = f;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    v = <T>(x) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'String' function, as required by the closure's context.
    v = <T>(x) => "hello";
    v = <T>(x) => 3;
//                ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    v = <T>(x) {return 3;};
//                     ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    v = <T>(x) {return x;};
//                     ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
  }
  {
    List<String> f<S>(int x) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'List<String>'.
    var v = f;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    v = <T>(int x) => null;
//                    ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'List<String>' function, as required by the closure's context.
    v = <T>(int x) => ["hello"];
    v = <T>(String x) => ["hello"];
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<String> Function<T>(String)' can't be assigned to a variable of type 'List<String> Function<S>(int)'.
    v = <T>(int x) => [3];
//                     ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
    v = <T>(int x) {return [3];};
//                          ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
  }
  {
    int int2int<S>(int x) => null;
//                           ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'int2int' because it has a return type of 'int'.
    String int2String<T>(int x) => null;
//                                 ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'int2String' because it has a return type of 'String'.
    String string2String<T>(String x) => null;
//                                       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'string2String' because it has a return type of 'String'.
    var x = int2int;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
    x = <T>(x) => x;
    x = <T>(x) => x+1;
    var y = int2String;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
    y = <T>(x) => x;
//                ^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'int' isn't returnable from a 'String' function, as required by the closure's context.
    y = <T>(x) => x.substring(3);
//                  ^^^^^^^^^
// [diag.undefinedMethod] The method 'substring' isn't defined for the type 'int'.
    var z = string2String;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
    z = <T>(x) => x.substring(3);
  }
}
''');
  }

  test_downwardsInferenceOnInstanceCreations_inferDownwards() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<S, T> {
  S x;
  T y;
  A(this.x, this.y);
  A.named(this.x, this.y);
}

class B<S, T> extends A<T, S> {
  B(S y, T x) : super(x, y);
  B.named(S y, T x) : super.named(x, y);
}

class C<S> extends B<S, S> {
  C(S a) : super(a, a);
  C.named(S a) : super.named(a, a);
}

class D<S, T> extends B<T, int> {
  D(T a) : super(a, 3);
  D.named(T a) : super.named(a, 3);
}

class E<S, T> extends A<C<S>, T> {
  E(T a) : super(null, a);
//               ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'C<S>'.
}

class F<S, T> extends A<S, T> {
  F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
//                     ^
// [diag.missingDefaultValueForParameter] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                                ^
// [diag.missingDefaultValueForParameter] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
  F.named(S x, T y, [S a, T b]) : super(a, b);
//                     ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'a' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                          ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
}

void main() {
  {
    A<int, String> a0 = new A(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
    A<int, String> a1 = new A.named(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
    A<int, String> a2 = new A<int, String>(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    A<int, String> a3 = new A<int, String>.named(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    A<int, String> a4 = new A<int, dynamic>(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'A<int, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
    A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'A<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
  }
  {
    A<int, String> a0 = new A("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                            ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                     ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
    A<int, String> a1 = new A.named("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                           ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
  }
  {
    A<int, String> a0 = new B("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
    A<int, String> a1 = new B.named("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
    A<int, String> a2 = new B<String, int>("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    A<int, String> a3 = new B<String, int>.named("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    A<int, String> a4 = new B<String, dynamic>("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'B<String, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
    A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'B<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
  }
  {
    A<int, String> a0 = new B(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                            ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
//                               ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
    A<int, String> a1 = new B.named(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
//                                     ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  }
  {
    A<int, int> a0 = new C(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
    A<int, int> a1 = new C.named(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
    A<int, int> a2 = new C<int>(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    A<int, int> a3 = new C<int>.named(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    A<int, int> a4 = new C<dynamic>(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                   ^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<dynamic>' can't be assigned to a variable of type 'A<int, int>'.
    A<int, int> a5 = new C<dynamic>.named(3);
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                   ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'C<dynamic>' can't be assigned to a variable of type 'A<int, int>'.
  }
  {
    A<int, int> a0 = new C("hello");
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                         ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
    A<int, int> a1 = new C.named("hello");
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                               ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  }
  {
    A<int, String> a0 = new D("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
    A<int, String> a1 = new D.named("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
    A<int, String> a2 = new D<int, String>("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    A<int, String> a3 = new D<String, String>.named("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    A<int, String> a4 = new D<num, dynamic>("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'D<num, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
    A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'D<dynamic, dynamic>' can't be assigned to a variable of type 'A<int, String>'.
  }
  {
    A<int, String> a0 = new D(3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
//                            ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
    A<int, String> a1 = new D.named(3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
//                                  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
  }
  {
    A<C<int>, String> a0 = new E("hello");
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
  }
  { // Check named and optional arguments
    A<int, String> a0 = new F(3, "hello",
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a0' isn't used.
        a: [3],
        b: ["hello"]);
    A<int, String> a1 = new F(3, "hello",
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a1' isn't used.
        a: ["hello"],
//          ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
        b: [3]);
//          ^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
    A<int, String> a2 = new F.named(3, "hello", 3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a2' isn't used.
    A<int, String> a3 = new F.named(3, "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a3' isn't used.
    A<int, String> a4 = new F.named(3, "hello", "hello", 3);
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a4' isn't used.
//                                              ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                                                       ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
    A<int, String> a5 = new F.named(3, "hello", "hello");
//                 ^^
// [diag.unusedLocalVariable] The value of the local variable 'a5' isn't used.
//                                              ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  }
}
''');
  }

  test_downwardsInferenceOnListLiterals_inferDownwards() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo([List<String> list1 = const [],
          List<String> list2 = const [42]]) {
//                                    ^^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
}

void main() {
  {
    List<int> l0 = [];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    List<int> l1 = [3];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    List<int> l2 = ["hello"];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                  ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
    List<int> l3 = ["hello", 3];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                  ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  }
  {
    List<dynamic> l0 = [];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    List<dynamic> l1 = [3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    List<dynamic> l2 = ["hello"];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
    List<dynamic> l3 = ["hello", 3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
  }
  {
    List<int> l0 = <num>[];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                 ^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
    List<int> l1 = <num>[3];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
//                 ^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
    List<int> l2 = <num>["hello"];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
//                 ^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
//                       ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'num'.
    List<int> l3 = <num>["hello", 3];
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                 ^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
//                       ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'num'.
  }
  {
    Iterable<int> i0 = [];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'i0' isn't used.
    Iterable<int> i1 = [3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'i1' isn't used.
    Iterable<int> i2 = ["hello"];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'i2' isn't used.
//                      ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
    Iterable<int> i3 = ["hello", 3];
//                ^^
// [diag.unusedLocalVariable] The value of the local variable 'i3' isn't used.
//                      ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  }
  {
    const List<int> c0 = const [];
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'c0' isn't used.
    const List<int> c1 = const [3];
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'c1' isn't used.
    const List<int> c2 = const ["hello"];
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'c2' isn't used.
//                              ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
    const List<int> c3 = const ["hello", 3];
//                  ^^
// [diag.unusedLocalVariable] The value of the local variable 'c3' isn't used.
//                              ^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'String' can't be assigned to the list type 'int'.
  }
}
''');
  }

  test_downwardsInferenceOnListLiterals_inferIfValueTypesMatchContext() async {
    await resolveTestCodeWithDiagnostics(r'''
class DartType {}
typedef void Asserter<T>(T type);
typedef Asserter<T> AsserterBuilder<S, T>(S arg);

Asserter<DartType> _isInt;
//                 ^^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable '_isInt' must be initialized.
Asserter<DartType> _isString;
//                 ^^^^^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable '_isString' must be initialized.

abstract class C {
  static AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
//                                                           ^^^^^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'assertBOf' must be initialized.
  static AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;
//                                                                            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'assertCOf' because it has a return type of 'AsserterBuilder<List<Asserter<DartType>>, DartType>'.

  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
//                                                    ^^^^^^^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'assertAOf' must be initialized.
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf([_isInt, _isString]);
    assertBOf([_isInt, _isString]);
    assertCOf([_isInt, _isString]);
    assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
  }

  abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
//                                                    ^^^^^^^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'assertAOf' must be initialized.
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf([_isInt, _isString]);
    this.assertAOf([_isInt, _isString]);
    this.assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
//                                                  ^^^^^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'assertBOf' must be initialized.
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;
//                                                                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'assertCOf' because it has a return type of 'AsserterBuilder<List<Asserter<DartType>>, DartType>'.

main() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  assertAOf([_isInt, _isString]);
//^^^^^^^^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'assertAOf' must be assigned before it can be used.
  assertBOf([_isInt, _isString]);
  assertCOf([_isInt, _isString]);
  C.assertBOf([_isInt, _isString]);
  C.assertCOf([_isInt, _isString]);

  C c;
  c.assertAOf([_isInt, _isString]);
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'c' must be assigned before it can be used.
  c.assertDOf([_isInt, _isString]);
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'c' must be assigned before it can be used.

  G<int> g;
  g.assertAOf([_isInt, _isString]);
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'g' must be assigned before it can be used.
  g.assertDOf([_isInt, _isString]);
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'g' must be assigned before it can be used.
}
''');
  }

  test_downwardsInferenceOnMapLiterals() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo([Map<int, String> m1 = const {1: "hello"},
    Map<int, String> m2 = const {
      // One error is from type checking and the other is from const evaluation.
      "hello": "world"
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
    }]) {
}
void main() {
  {
    Map<int, String> l0 = {};
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    Map<int, String> l1 = {3: "hello"};
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Map<int, String> l2 = {
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
      "hello": "hello"
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
    };
    Map<int, String> l3 = {
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
      3: 3
//       ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    };
    Map<int, String> l4 = {
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
      3: "hello",
      "hello": 3
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
//             ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    };
  }
  {
    Map<dynamic, dynamic> l0 = {};
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    Map<dynamic, dynamic> l1 = {3: "hello"};
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Map<dynamic, dynamic> l2 = {"hello": "hello"};
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
    Map<dynamic, dynamic> l3 = {3: 3};
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
    Map<dynamic, dynamic> l4 = {3:"hello", "hello": 3};
//                        ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
  }
  {
    Map<dynamic, String> l0 = {};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    Map<dynamic, String> l1 = {3: "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Map<dynamic, String> l2 = {"hello": "hello"};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
    Map<dynamic, String> l3 = {3: 3};
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                                ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    Map<dynamic, String> l4 = {
//                       ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
      3: "hello",
      "hello": 3
//             ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    };
  }
  {
    Map<int, dynamic> l0 = {};
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    Map<int, dynamic> l1 = {3: "hello"};
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    Map<int, dynamic> l2 = {
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
      "hello": "hello"
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
    };
    Map<int, dynamic> l3 = {3: 3};
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
    Map<int, dynamic> l4 = {
//                    ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
      3:"hello",
      "hello": 3
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
    };
  }
  {
    Map<int, String> l0 = <num, dynamic>{};
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
//                        ^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<num, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
    Map<int, String> l1 = <num, dynamic>{3: "hello"};
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
//                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<num, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
    Map<int, String> l3 = <num, dynamic>{3: 3};
//                   ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
//                        ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'Map<num, dynamic>' can't be assigned to a variable of type 'Map<int, String>'.
  }
  {
    const Map<int, String> l0 = const {};
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l0' isn't used.
    const Map<int, String> l1 = const {3: "hello"};
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l1' isn't used.
    const Map<int, String> l2 = const {
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l2' isn't used.
      "hello": "hello"
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
    };
    const Map<int, String> l3 = const {
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l3' isn't used.
      3: 3
//       ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    };
    const Map<int, String> l4 = const {
//                         ^^
// [diag.unusedLocalVariable] The value of the local variable 'l4' isn't used.
      3:"hello",
      "hello": 3
//    ^^^^^^^
// [diag.mapKeyTypeNotAssignable] The element type 'String' can't be assigned to the map key type 'int'.
//             ^
// [diag.mapValueTypeNotAssignable] The element type 'int' can't be assigned to the map value type 'String'.
    };
  }
}
''');
  }

  test_fieldRefersToStaticGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final x = _x;
  static int get _x => null;
//                     ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function '_x' because it has a return type of 'int'.
}
''');
    var x = result.libraryElement.classes[0].fields[0];
    _assertTypeStr(x.type, 'int');
  }

  test_fieldRefersToTopLevelGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final x = y;
}
int get y => null;
//           ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'y' because it has a return type of 'int'.
''');
    var x = result.libraryElement.classes[0].fields[0];
    _assertTypeStr(x.type, 'int');
  }

  test_futureOr_subtyping() async {
    await resolveTestCodeWithDiagnostics(r'''
void add(int x) {}
add2(int y) {}
void foo(Future<int> f) {
  var a = f.then(add);

  var b = f.then(add2);

  (a, b);
}
''');
  }

  test_futureThen_conditional_declaredFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(Future<bool> f) {
  Future<int> t1 = f.then(
    (x) async => x ? 2 : await new Future<int>.value(3),
  );

  // Note: Why the duplicate here?
  Future<int> t2 = f.then((x) async {
    return await x ? 2 : new Future<int>.value(3);
  });

  Future<int> t5 = f.then((x) => x ? 2 : new Future<int>.value(3));

  Future<int> t6 = f.then((x) {
    return x ? 2 : new Future<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_conditional_declaredFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(Future<bool> f) {
  Future<int> t1 = f.then(
    (x) async => x ? 2 : await new MyFuture<int>.value(3),
  );

  // Note: Why the duplicate here?
  Future<int> t2 = f.then((x) async {
    return await x ? 2 : new MyFuture<int>.value(3);
  });

  Future<int> t5 = f.then((x) => x ? 2 : new MyFuture<int>.value(3));

  Future<int> t6 = f.then((x) {
    return x ? 2 : new MyFuture<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_conditional_declaredMyFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture<bool> f) {
  Future<int> t1 = f.then(
    (x) async => x ? 2 : await new Future<int>.value(3),
  );

  // Note: Why the duplicate here?
  Future<int> t2 = f.then((x) async {
    return await x ? 2 : new Future<int>.value(3);
  });

  Future<int> t5 = f.then((x) => x ? 2 : new Future<int>.value(3));

  Future<int> t6 = f.then((x) {
    return x ? 2 : new Future<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_conditional_declaredMyFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture<bool> f) {
  Future<int> t1 = f.then(
    (x) async => x ? 2 : await new MyFuture<int>.value(3),
  );

  // Note: Why the duplicate here?
  Future<int> t2 = f.then((x) async {
    return await x ? 2 : new MyFuture<int>.value(3);
  });

  Future<int> t5 = f.then((x) => x ? 2 : new MyFuture<int>.value(3));

  Future<int> t6 = f.then((x) {
    return x ? 2 : new MyFuture<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_conditional_declaredMyFuture_downwardsMyFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture<bool> f) {
  MyFuture<int> t1 = f.then(
    (x) async => x ? 2 : await new Future<int>.value(3),
  );

  // Note: Why the duplicate here?
  MyFuture<int> t2 = f.then((x) async {
    return await x ? 2 : new Future<int>.value(3);
  });

  MyFuture<int> t5 = f.then((x) => x ? 2 : new Future<int>.value(3));

  MyFuture<int> t6 = f.then((x) {
    return x ? 2 : new Future<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_conditional_declaredMyFuture_downwardsMyFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture<bool> f) {
  MyFuture<int> t1 = f.then(
    (x) async => x ? 2 : await new MyFuture<int>.value(3),
  );

  // Note: Why the duplicate here?
  MyFuture<int> t2 = f.then((x) async {
    return await x ? 2 : new MyFuture<int>.value(3);
  });

  MyFuture<int> t5 = f.then((x) => x ? 2 : new MyFuture<int>.value(3));

  MyFuture<int> t6 = f.then((x) {
    return x ? 2 : new MyFuture<int>.value(3);
  });

  (t1, t2, t5, t6);
}
''');
  }

  test_futureThen_declaredFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(Future f) {
  Future<int> t1 = f.then((_) async => await new Future<int>.value(1));

  Future<int> t2 = f.then((_) async {
    return await new Future<int>.value(2);
  });

  Future<int> t3 = f.then((_) async => 3);

  Future<int> t4 = f.then((_) async {
    return 4;
  });

  Future<int> t5 = f.then((_) => new Future<int>.value(5));

  Future<int> t6 = f.then((_) {
    return new Future<int>.value(6);
  });

  Future<int> t7 = f.then((_) async => new Future<int>.value(7));

  Future<int> t8 = f.then((_) async {
    return new Future<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_declaredFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(Future f) {
  Future<int> t1 = f.then((_) async => await new MyFuture<int>.value(1));

  Future<int> t2 = f.then((_) async {
    return await new MyFuture<int>.value(2);
  });

  Future<int> t3 = f.then((_) async => 3);

  Future<int> t4 = f.then((_) async {
    return 4;
  });

  Future<int> t5 = f.then((_) => new MyFuture<int>.value(5));

  Future<int> t6 = f.then((_) {
    return new MyFuture<int>.value(6);
  });

  Future<int> t7 = f.then((_) async => new MyFuture<int>.value(7));

  Future<int> t8 = f.then((_) async {
    return new MyFuture<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_declaredMyFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture f) {
  Future<int> t1 = f.then((_) async => await new Future<int>.value(1));

  Future<int> t2 = f.then((_) async {
    return await new Future<int>.value(2);
  });

  Future<int> t3 = f.then((_) async => 3);

  Future<int> t4 = f.then((_) async {
    return 4;
  });

  Future<int> t5 = f.then((_) => new Future<int>.value(5));

  Future<int> t6 = f.then((_) {
    return new Future<int>.value(6);
  });

  Future<int> t7 = f.then((_) async => new Future<int>.value(7));

  Future<int> t8 = f.then((_) async {
    return new Future<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_declaredMyFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture f) {
  Future<int> t1 = f.then((_) async => await new MyFuture<int>.value(1));

  Future<int> t2 = f.then((_) async {
    return await new MyFuture<int>.value(2);
  });

  Future<int> t3 = f.then((_) async => 3);

  Future<int> t4 = f.then((_) async {
    return 4;
  });

  Future<int> t5 = f.then((_) => new MyFuture<int>.value(5));

  Future<int> t6 = f.then((_) {
    return new MyFuture<int>.value(6);
  });

  Future<int> t7 = f.then((_) async => new MyFuture<int>.value(7));

  Future<int> t8 = f.then((_) async {
    return new MyFuture<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_declaredMyFuture_downwardsMyFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture f) {
  MyFuture<int> t1 = f.then((_) async => await new Future<int>.value(1));

  MyFuture<int> t2 = f.then((_) async {
    return await new Future<int>.value(2);
  });

  MyFuture<int> t3 = f.then((_) async => 3);

  MyFuture<int> t4 = f.then((_) async {
    return 4;
  });

  MyFuture<int> t5 = f.then((_) => new Future<int>.value(5));

  MyFuture<int> t6 = f.then((_) {
    return new Future<int>.value(6);
  });

  MyFuture<int> t7 = f.then((_) async => new Future<int>.value(7));

  MyFuture<int> t8 = f.then((_) async {
    return new Future<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_declaredMyFuture_downwardsMyFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void foo(MyFuture f) {
  MyFuture<int> t1 = f.then((_) async => await new MyFuture<int>.value(1));

  MyFuture<int> t2 = f.then((_) async {
    return await new MyFuture<int>.value(2);
  });

  MyFuture<int> t3 = f.then((_) async => 3);

  MyFuture<int> t4 = f.then((_) async {
    return 4;
  });

  MyFuture<int> t5 = f.then((_) => new MyFuture<int>.value(5));

  MyFuture<int> t6 = f.then((_) {
    return new MyFuture<int>.value(6);
  });

  MyFuture<int> t7 = f.then((_) async => new MyFuture<int>.value(7));

  MyFuture<int> t8 = f.then((_) async {
    return new MyFuture<int>.value(8);
  });

  (t1, t2, t3, t4, t5, t6, t7, t8);
}
''');
  }

  test_futureThen_downwardsMethodTarget() async {
    // Not working yet, see: https://github.com/dart-lang/sdk/issues/27114
    await resolveTestCodeWithDiagnostics(r'''
void foo(Future<int> f) {
  Future<List<int>> b = f
// [diag.invalidAssignment][column 25][length 51] A value of type 'Future<List<dynamic>>' can't be assigned to a variable of type 'Future<List<int>>'.
      .then((x) => [])
      .whenComplete(() {});
  b = f.then((x) => []);
  b;
}
''');
  }

  test_futureThen_explicitFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void foo1(Future<int> f) {
  var x = f.then<Future<List<int>>>((x) => []);
//                                         ^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'List<dynamic>' isn't returnable from a 'FutureOr<Future<List<int>>>' function, as required by the closure's context.
  Future<List<int>> y = x;
//                      ^
// [diag.invalidAssignment] A value of type 'Future<Future<List<int>>>' can't be assigned to a variable of type 'Future<List<int>>'.
  y;
}

void foo2(Future<int> f) {
  var x = f.then<List<int>>((x) => []);
  Future<List<int>> y = x;
  y;
}
''');
  }

  test_futureThen_upwards_declaredFuture_downwardsFuture_upwardsFuture() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27088.
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void main() {
  var f = foo().then((_) => 2.3);
  Future<int> f2 = f;
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'f2' isn't used.
//                 ^
// [diag.invalidAssignment] A value of type 'Future<double>' can't be assigned to a variable of type 'Future<int>'.

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  Future<num> f3 = foo().then(
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'f3' isn't used.
// [diag.unnecessaryCast][column 20][length 47] Unnecessary cast.
      (_) => 2.3) as Future<double>;
}
Future foo() => new Future<int>.value(1);
''');
  }

  test_futureThen_upwards_declaredMyFuture_downwardsFuture_upwardsFuture() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27088.
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void main() {
  var f = foo().then((_) => 2.3);
  Future<int> f2 = f;
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'f2' isn't used.
//                 ^
// [diag.invalidAssignment] A value of type 'MyFuture<double>' can't be assigned to a variable of type 'Future<int>'.

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  Future<num> f3 = foo().then(
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'f3' isn't used.
      (_) => 2.3) as Future<double>;
}
MyFuture foo() => new MyFuture<int>.value(1);
''');
  }

  test_futureThen_upwards_declaredMyFuture_downwardsMyFuture_upwardsMyFuture() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27088.
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

void main() {
  var f = foo().then((_) => 2.3);
  MyFuture<int> f2 = f;
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'f2' isn't used.
//                   ^
// [diag.invalidAssignment] A value of type 'MyFuture<double>' can't be assigned to a variable of type 'MyFuture<int>'.

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  MyFuture<num> f3 = foo().then(
//              ^^
// [diag.unusedLocalVariable] The value of the local variable 'f3' isn't used.
// [diag.unnecessaryCast][column 22][length 49] Unnecessary cast.
      (_) => 2.3) as MyFuture<double>;
}
MyFuture foo() => new MyFuture<int>.value(1);
''');
  }

  test_futureThen_upwardsFromBlock() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27113.
    await resolveTestCodeWithDiagnostics(r'''
main() {
  Future<int> base;
  var f = base.then((x) {
//        ^^^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'base' must be assigned before it can be used.
    return x == 0;
  });
  var g = base.then((x) => x == 0);
//        ^^^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'base' must be assigned before it can be used.
  Future<bool> b = f;
//             ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  b = g;
}
''');
  }

  test_futureUnion_asyncConditional_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

Future<int> g1(bool x) async {
  return x ? 42 : new Future.value(42); }
Future<int> g2(bool x) async =>
  x ? 42 : new Future.value(42);
Future<int> g3(bool x) async {
  var y = x ? 42 : new Future.value(42);
  return y;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Object' can't be returned from the function 'g3' because it has a return type of 'Future<int>'.
}
''');
  }

  test_futureUnion_asyncConditional_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

Future<int> g1(bool x) async {
  return x ? 42 : new MyFuture.value(42); }
Future<int> g2(bool x) async =>
  x ? 42 : new MyFuture.value(42);
Future<int> g3(bool x) async {
  var y = x ? 42 : new MyFuture.value(42);
  return y;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Object' can't be returned from the function 'g3' because it has a return type of 'Future<int>'.
}
''');
  }

  test_futureUnion_downwards_declaredFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

Future f;
//     ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
// Instantiates Future<int>
Future<int> t1 = f.then((_) =>
   new Future.value('hi'));
//                  ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'FutureOr<int>?'.

// Instantiates List<int>
Future<List<int>> t2 = f.then((_) => [3]);
Future<List<int>> g2() async { return [3]; }
Future<List<int>> g3() async {
  return new Future.value(
      [3]); }
''');
  }

  test_futureUnion_downwards_declaredFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

Future f;
//     ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
// Instantiates Future<int>
Future<int> t1 = f.then((_) =>
   new MyFuture.value('hi'));
//                    ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int?'.

// Instantiates List<int>
Future<List<int>> t2 = f.then((_) => [3]);
Future<List<int>> g2() async { return [3]; }
Future<List<int>> g3() async {
  return new MyFuture.value(
      [3]); }
''');
  }

  test_futureUnion_downwards_declaredMyFuture_downwardsFuture_upwardsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

MyFuture f;
//       ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
// Instantiates Future<int>
Future<int> t1 = f.then((_) =>
   new Future.value('hi'));
//                  ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'FutureOr<int>?'.

// Instantiates List<int>
Future<List<int>> t2 = f.then((_) => [3]);
Future<List<int>> g2() async { return [3]; }
Future<List<int>> g3() async {
  return new Future.value(
      [3]); }
''');
  }

  test_futureUnion_downwards_declaredMyFuture_downwardsFuture_upwardsMyFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([T? x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> Function(T) f, {Function? onError}) {
    return MyFuture<S>();
  }
}

MyFuture f;
//       ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'f' must be initialized.
// Instantiates Future<int>
Future<int> t1 = f.then((_) =>
   new MyFuture.value('hi'));
//                    ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int?'.

// Instantiates List<int>
Future<List<int>> t2 = f.then((_) => [3]);
Future<List<int>> g2() async { return [3]; }
Future<List<int>> g3() async {
  return new MyFuture.value(
      [3]); }
''');
  }

  test_futureUnion_downwardsGenericMethodWithFutureReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27134
    //
    // We need to take a future union into account for both directions of
    // generic method inference.
    await resolveTestCodeWithDiagnostics(r'''
foo() async {
  Future<List<A>> f1 = null;
//                     ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Future<List<A>>'.
  Future<List<A>> f2 = null;
//                     ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Future<List<A>>'.
  List<List<A>> merged = await Future.wait([f1, f2]);
//              ^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'merged' isn't used.
}

class A {}
''');
  }

  test_futureUnion_downwardsGenericMethodWithGenericReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27284
    await resolveTestCodeWithDiagnostics(r'''
T id<T>(T x) => x;

foo(Future<String> f) async {
  String s = await id(f);
  s;
}
''');
  }

  test_futureUnion_upwardsGenericMethods() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27151
    await resolveTestCodeWithDiagnostics(r'''
main() async {
  var b = new Future<B>.value(new B());
  var c = new Future<C>.value(new C());
  var lll = [b, c];
  var result = await Future.wait(lll);
  var result2 = await Future.wait([b, c]);
  List<A> list = result;
//        ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'list' isn't used.
  list = result2;
}

class A {}
class B extends A {}
class C extends A {}
''');
  }

  test_genericFunctions_returnTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void ToValue<T>(T value);

main() {
  ToValue<T> f<T>(T x) => null;
//                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'ToValue<T>'.
  var x = f<int>(42);
  var y = f(42);
  ToValue<int> takesInt = x;
//             ^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'takesInt' isn't used.
  takesInt = y;
}
''');
  }

  test_genericMethods_basicDownwardInference() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<S, T>(S s) => null;
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
main() {
  String x = f(42);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  String y = (f)(42);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
  }

  test_genericMethods_dartMathMinMax() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:math';

void printInt(int x) => print(x);
void printDouble(double x) => print(x);

num myMax(num x, num y) => max(x, y);

main() {
  // Okay if static types match.
  printInt(max(1, 2));
  printInt(min(1, 2));
  printDouble(max(1.0, 2.0));
  printDouble(min(1.0, 2.0));

  // No help for user-defined functions from num->num->num.
  printInt(myMax(1, 2));
//         ^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
  printInt(myMax(1, 2) as int);

  // An int context means doubles are rejected
  printInt(max(1, 2.0));
//                ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  printInt(min(1, 2.0));
//                ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  // A double context means ints are accepted as doubles
  printDouble(max(1, 2.0));
  printDouble(min(1, 2.0));

  // Types other than int and double are not accepted.
  printInt(min("hi", "there"));
//             ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
//                   ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
''');
  }

  test_genericMethods_doNotInferInvalidOverrideOfGenericMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
T m<T>(T x) => x;
//^
// [context 1] The member being overridden.
}
class D extends C {
m(x) => x;
// [diag.invalidOverride][column 1][length 1][context 1] 'D.m' ('dynamic Function(dynamic)') isn't a valid override of 'C.m' ('T Function<T>(T)').
}
main() {
  int y = new D().m<int>(42);
//                 ^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'm' is declared with 0 type parameters, but 1 type arguments are given.
  print(y);
}
''');
  }

  test_genericMethods_downwardsInferenceAffectsArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(List<T> s) => null;
//                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'T'.
main() {
  String x = f(['hi']);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  String y = f([42]);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^^
// [diag.listElementTypeNotAssignable] The element type 'int' can't be assigned to the list type 'String'.
}
''');
  }

  test_genericMethods_downwardsInferenceFold() async {
    // Regression from https://github.com/dart-lang/sdk/issues/25491
    // The first example works now, but the latter requires a full solution to
    // https://github.com/dart-lang/sdk/issues/25490
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  List<int> o;
  int y = o.fold(0, (x, y) => x + y);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  var z = o.fold(0, (x, y) => x + y);
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  y = z;
}
void functionExpressionInvocation() {
  List<int> o;
  int y = (o.fold)(0, (x, y) => x + y);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  var z = (o.fold)(0, (x, y) => x + y);
//         ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'o' must be assigned before it can be used.
  y = z;
}
''');
  }

  test_genericMethods_handleOverrideOfNonGenericWithGeneric() async {
    // Regression test for crash when adding genericity
    await resolveTestCodeWithDiagnostics('''
class C {
  m(x) => x;
//^
// [context 1] The member being overridden.
  dynamic g(int x) => x;
//        ^
// [context 2] The member being overridden.
}
class D extends C {
  T m<T>(T x) => x;
//  ^
// [diag.invalidOverride][context 1] 'D.m' ('T Function<T>(T)') isn't a valid override of 'C.m' ('dynamic Function(dynamic)').
  T g<T>(T x) => x;
//  ^
// [diag.invalidOverride][context 2] 'D.g' ('T Function<T>(T)') isn't a valid override of 'C.g' ('dynamic Function(int)').
}
main() {
  int y = (new D() as C).m(42);
  print(y);
}
''');
  }

  test_genericMethods_inferenceError() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  List<String> y;
  Iterable<String> x = y.map((String z) => 1.0);
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                     ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'y' must be assigned before it can be used.
//                                         ^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'double' isn't returnable from a 'String' function, as required by the closure's context.
}
''');
  }

  test_genericMethods_inferGenericFunctionParameterType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> extends D<T> {
  f<U>(x) { return null; }
//                 ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'F<U>'.
}
class D<T> {
  F<U> f<U>(U u) => null;
//                  ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'F<U>'.
}
typedef void F<V>(V v);
''');
    var f = result.libraryElement.getClass('C')!.methods[0];
    _assertTypeStr(f.type, 'void Function(U) Function<U>(U)');
  }

  test_genericMethods_inferGenericFunctionParameterType2() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> extends D<T> {
  f<U>(g) => null;
}
abstract class D<T> {
  void f<U>(G<U> g);
}
typedef List<V> G<V>();
''');
    var f = result.libraryElement.getClass('C')!.methods[0];
    _assertTypeStr(f.type, 'void Function<U>(List<U> Function())');
  }

  test_genericMethods_inferGenericFunctionReturnType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> extends D<T> {
  f<U>(x) { return null; }
//                 ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'F<U>'.
}
class D<T> {
  F<U> f<U>(U u) => null;
//                  ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'F<U>'.
}
typedef V F<V>();
''');
    var f = result.libraryElement.getClass('C')!.methods[0];
    _assertTypeStr(f.type, 'U Function() Function<U>(U)');
  }

  test_genericMethods_inferGenericMethodType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25668
    await resolveTestCodeWithDiagnostics('''
class C {
  T m<T>(T x) => x;
}
class D extends C {
  m<S>(x) => x;
}
main() {
  int y = new D().m<int>(42);
  print(y);
}
''');
  }

  test_genericMethods_IterableAndFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> make(int x) => (new Future(() => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(list);
  Future<String> results2 = results.then((List<int> list)
//               ^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'results2' isn't used.
    => list.fold('', (x, y) => x + y.toString()));
//                               ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type 'FutureOr<String>'.

  Future<String> results3 = results.then((List<int> list)
//               ^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'results3' isn't used.
    => list.fold('', (String x, y) => x + y.toString()));
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String Function(String, int)' can't be assigned to the parameter type 'FutureOr<String> Function(FutureOr<String>, int)'.

  Future<String> results4 = results.then((List<int> list)
//               ^^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'results4' isn't used.
    => list.fold<String>('', (x, y) => x + y.toString()));
}
''');
  }

  test_genericMethods_nestedGenericInstantiation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as math;
class Trace {
  List<Frame> frames = [];
}
class Frame {
  String location = '';
}
main() {
  List<Trace> traces = [];
  var longest = traces.map((trace) {
//    ^^^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'longest' isn't used.
    return trace.frames.map((frame) => frame.location.length)
        .fold(0, math.max);
  }).fold(0, math.max);
}
''');
  }

  test_genericMethods_usesGreatestLowerBound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'generic' because it has a return type of 'T'.

main() {
  var v = generic((F f) => null, (G g) => null);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int> Function(num)');
  }

  test_genericMethods_usesGreatestLowerBound_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;
//                              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'generic' because it has a return type of 'T'.

var v = generic((F f) => null, (G g) => null);
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<int> Function(num)');
  }

  test_infer_assignToIndex() async {
    await resolveTestCodeWithDiagnostics(r'''
List<double> a = <double>[];
var b = (a[0] = 1.0);
''');
  }

  test_infer_assignToProperty() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int f;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'f' must be initialized.
}
var v_assign = (new A().f = 1);
var v_plus = (new A().f += 1);
var v_minus = (new A().f -= 1);
var v_multiply = (new A().f *= 1);
var v_prefix_pp = (++new A().f);
var v_prefix_mm = (--new A().f);
var v_postfix_pp = (new A().f++);
var v_postfix_mm = (new A().f--);
''');
  }

  test_infer_assignToProperty_custom() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator +(other) => this;
  A operator -(other) => this;
}
class B {
  A a;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'a' must be initialized.
}
var v_prefix_pp = (++new B().a);
var v_prefix_mm = (--new B().a);
var v_postfix_pp = (new B().a++);
var v_postfix_mm = (new B().a--);
''');
  }

  test_infer_assignToRef() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int f;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'f' must be initialized.
}
A a = new A();
var b = (a.f = 1);
var c = 0;
var d = (c = 1);
''');
  }

  test_infer_binary_custom() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}
var v_add = new A() + 'foo';
var v_minus = new A() - 'bar';
''');
  }

  test_infer_binary_doubleDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
var a_equal = 1.0 == 2.0;
var a_notEqual = 1.0 != 2.0;
var a_add = 1.0 + 2.0;
var a_subtract = 1.0 - 2.0;
var a_multiply = 1.0 * 2.0;
var a_divide = 1.0 / 2.0;
var a_floorDivide = 1.0 ~/ 2.0;
var a_greater = 1.0 > 2.0;
var a_less = 1.0 < 2.0;
var a_greaterEqual = 1.0 >= 2.0;
var a_lessEqual = 1.0 <= 2.0;
var a_modulo = 1.0 % 2.0;
''');
  }

  test_infer_binary_doubleInt() async {
    await resolveTestCodeWithDiagnostics(r'''
var a_equal = 1.0 == 2;
var a_notEqual = 1.0 != 2;
var a_add = 1.0 + 2;
var a_subtract = 1.0 - 2;
var a_multiply = 1.0 * 2;
var a_divide = 1.0 / 2;
var a_floorDivide = 1.0 ~/ 2;
var a_greater = 1.0 > 2;
var a_less = 1.0 < 2;
var a_greaterEqual = 1.0 >= 2;
var a_lessEqual = 1.0 <= 2;
var a_modulo = 1.0 % 2;
''');
  }

  test_infer_binary_intDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
var a_equal = 1 == 2.0;
var a_notEqual = 1 != 2.0;
var a_add = 1 + 2.0;
var a_subtract = 1 - 2.0;
var a_multiply = 1 * 2.0;
var a_divide = 1 / 2.0;
var a_floorDivide = 1 ~/ 2.0;
var a_greater = 1 > 2.0;
var a_less = 1 < 2.0;
var a_greaterEqual = 1 >= 2.0;
var a_lessEqual = 1 <= 2.0;
var a_modulo = 1 % 2.0;
''');
  }

  test_infer_binary_intInt() async {
    await resolveTestCodeWithDiagnostics(r'''
var a_equal = 1 == 2;
var a_notEqual = 1 != 2;
var a_bitXor = 1 ^ 2;
var a_bitAnd = 1 & 2;
var a_bitOr = 1 | 2;
var a_bitShiftRight = 1 >> 2;
var a_bitShiftLeft = 1 << 2;
var a_add = 1 + 2;
var a_subtract = 1 - 2;
var a_multiply = 1 * 2;
var a_divide = 1 / 2;
var a_floorDivide = 1 ~/ 2;
var a_greater = 1 > 2;
var a_less = 1 < 2;
var a_greaterEqual = 1 >= 2;
var a_lessEqual = 1 <= 2;
var a_modulo = 1 % 2;
''');
  }

  test_infer_conditional() async {
    await resolveTestCodeWithDiagnostics(r'''
var a = 1 == 2 ? 1 : 2.0;
var b = 1 == 2 ? 1.0 : 2;
''');
  }

  test_infer_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
var a_not = !true;
var a_complement = ~1;
var a_negate = -1;
''');
  }

  test_infer_prefixExpression_custom() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
  int operator ~() => 1;
  double operator -() => 2.0;
}
var a = new A();
var v_complement = ~a;
var v_negate = -a;
''');
  }

  test_infer_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
var t = true;
var a = (throw 0);
var b = (throw 0) ? 1 : 2;
//                  ^
// [diag.deadCode] Dead code.
//                      ^
// [diag.deadCode] Dead code.
var c = t ? (throw 1) : 2;
var d = t ? 1 : (throw 2);
''');
  }

  test_infer_typeCast() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class B<T> extends A<T> {
  foo() {}
}
A<num> a = new B<int>();
var b = (a as B<int>);
main() {
  b.foo();
}
''');
  }

  test_infer_typedListLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
var a = <int>[];
var b = <double>[1.0, 2.0, 3.0];
var c = <List<int>>[];
var d = <dynamic>[1, 2.0, false];
''');
  }

  test_infer_typedMapLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
var a = <int, String>{0: 'aaa', 1: 'bbb'};
var b = <double, int>{1.1: 1, 2.2: 2};
var c = <List<int>, Map<String, double>>{};
var d = <int, dynamic>{};
var e = <dynamic, int>{};
var f = <dynamic, dynamic>{};
''');
  }

  test_infer_use_of_void() async {
    var result = await resolveTestCodeWithDiagnostics('''
class B {
  void f() {}
}
class C extends B {
  f() {}
}
var x = new C().f();
''');
    var x = result.findElement.topVar('x');
    assertType(x.type, 'void');
  }

  test_inferConstsTransitively() async {
    newFile('$testPackageLibPath/b.dart', '''
const b1 = 2;
''');

    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
import 'b.dart';
const a1 = m2;
const a2 = b1;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
const m1 = a1;
const m2 = a2;

foo() {
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  i = m1;
}
''');
  }

  test_inferCorrectlyOnMultipleVariablesDeclaredTogether() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var x, y = 2, z = "hi";
}

class B implements A {
  var x = 2, y = 3, z, w = 2;
//                  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'z' must be initialized.
}

foo() {
  String s;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 's' isn't used.
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.

  s = new B().x;
  s = new B().y;
//    ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  s = new B().z;
  s = new B().w;
//    ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.

  i = new B().x;
  i = new B().y;
  i = new B().z;
//    ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  i = new B().w;
}
''');
  }

  test_inferFromComplexExpressionsIfOuterMostValueIsPrecise() async {
    await resolveTestCodeWithDiagnostics(r'''
class A { int x; B operator+(other) => null; }
//            ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'x' must be initialized.
//                                     ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method '+' because it has a return type of 'B'.
class B extends A { B(ignore); }
var a = new A();
// Note: it doesn't matter that some of these refer to 'x'.
var b = new B(x);  // allocations
//            ^
// [diag.undefinedIdentifier] Undefined name 'x'.
var c1 = [x];      // list literals
//        ^
// [diag.undefinedIdentifier] Undefined name 'x'.
var c2 = const [];
var d = <dynamic, dynamic>{'a': 'b'};     // map literals
var e = new A()..x = 3; // cascades
var f = 2 + 3;          // binary expressions are OK if the left operand
                        // is from a library in a different strongest
                        // connected component.
var g = -3;
var h = new A() + 3;
var i = - new A();
//      ^
// [diag.undefinedOperator] The operator 'unary-' isn't defined for the type 'A'.
var j = null as B;
//      ^^^^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.

test1() {
  a = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'A'.
  a = new B(3);
  b = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'B'.
  b = new B(3);
  c1 = [];
  c1 = {};
//     ^^
// [diag.invalidAssignment] A value of type 'Set<dynamic>' can't be assigned to a variable of type 'List<InvalidType>'.
  c2 = [];
  c2 = {};
//     ^^
// [diag.invalidAssignment] A value of type 'Set<dynamic>' can't be assigned to a variable of type 'List<dynamic>'.
  d = {};
  d = 3;
//    ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'Map<dynamic, dynamic>'.
  e = new A();
  e = {};
//    ^^
// [diag.invalidAssignment] A value of type 'Map<dynamic, dynamic>' can't be assigned to a variable of type 'A'.
  f = 3;
  f = false;
//    ^^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
  g = 1;
  g = false;
//    ^^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
  h = false;
//    ^^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'B'.
  h = new B('b');
  i = false;
  j = new B('b');
  j = false;
//    ^^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'B'.
  j = [];
//    ^^
// [diag.invalidAssignment] A value of type 'List<dynamic>' can't be assigned to a variable of type 'B'.
}
''');
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var x;
}

class B implements A {
  var x = 2;
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final x = null;
}

class B implements A {
  final x = 2;
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
var x = 2; // ok to infer
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
var y = x; // now ok :)

test1() {
  // ignore:unused_local_variable
  int t = 3;
  t = x;
  t = y;
}
''');
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn2() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
class A { static var x = 2; }
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  // ignore:unused_local_variable
  int t = 3;
  t = A.x;
  t = B.y;
}
''');
  }

  test_inferFromVariablesInNonCycleImportsWithFlag() async {
    newFile('$testPackageLibPath/a.dart', '''
var x = 2;
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
var y = x;

test1() {
  x = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  y = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_inferFromVariablesInNonCycleImportsWithFlag2() async {
    newFile('$testPackageLibPath/a.dart', '''
class A { static var x = 2; }
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  A.x = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  B.y = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_inferGenericMethodType_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T m<T>(int a, {String b, T c}) => null;
//                      ^
// [diag.missingDefaultValueForParameter] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                           ^
// [diag.missingDefaultValueForParameter] The parameter 'c' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                                  ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'T'.
}
main() {
 var y = new C().m(1, b: 'bbb', c: 2.0);
//   ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T m<T>(int a, [T b]) => null;
//                 ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                        ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'T'.
}
main() {
  var y = new C().m(1, 2.0);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_positional2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T m<T>(int a, [String b, T c]) => null;
//                      ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'b' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                           ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'c' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                                  ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'T'.
}
main() {
  var y = new C().m(1, 'bbb', 2.0);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_required() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  T m<T>(T x) => x;
}
main() {
  var y = new C().m(42);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'int');
  }

  test_inferListLiteralNestedInMapLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
class Resource {}
class Folder extends Resource {}

Resource getResource(String str) => null;
//                                  ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'getResource' because it has a return type of 'Resource'.

class Foo<T> {
  Foo(T t);
}

main() {
  // List inside map
  var map = <String, List<Folder>>{
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'map' isn't used.
    'pkgA': [getResource('/pkgA/lib/')],
//           ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'Resource' can't be assigned to the list type 'Folder'.
    'pkgB': [getResource('/pkgB/lib/')]
//           ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'Resource' can't be assigned to the list type 'Folder'.
  };
  // Also try map inside list
  var list = <Map<String, Folder>>[
//    ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'list' isn't used.
    { 'pkgA': getResource('/pkgA/lib/') },
//            ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mapValueTypeNotAssignable] The element type 'Resource' can't be assigned to the map value type 'Folder'.
    { 'pkgB': getResource('/pkgB/lib/') },
//            ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mapValueTypeNotAssignable] The element type 'Resource' can't be assigned to the map value type 'Folder'.
  ];
  // Instance creation too
  var foo = new Foo<List<Folder>>(
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
    [getResource('/pkgA/lib/')]
//   ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.listElementTypeNotAssignable] The element type 'Resource' can't be assigned to the list type 'Folder'.
  );
}
''');
  }

  test_inferLocalFunctionReturnType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26414
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  f0 () => 42;
//^^
// [diag.unusedElement] The declaration 'f0' isn't referenced.
  f1 () async => 42;
//^^
// [diag.unusedElement] The declaration 'f1' isn't referenced.

  f2 () { return 42; }
//^^
// [diag.unusedElement] The declaration 'f2' isn't referenced.
  f3 () async { return 42; }
//^^
// [diag.unusedElement] The declaration 'f3' isn't referenced.
  f4 () sync* { yield 42; }
//^^
// [diag.unusedElement] The declaration 'f4' isn't referenced.
  f5 () async* { yield 42; }

  num f6() => 42;
//    ^^
// [diag.unusedElement] The declaration 'f6' isn't referenced.

  f7 () => f7();
//^^
// [diag.unusedElement] The declaration 'f7' isn't referenced.
  f8 () => f9();
//^^
// [diag.unusedElement] The declaration 'f8' isn't referenced.
//         ^^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'f9' can't be referenced before it is declared.
  f9 () => f5();
//^^
// [context 1] The declaration of 'f9' is here.
}
''');

    void assertLocalFunctionType(String name, String expected) {
      var type = result.findElement.localFunction(name).type;
      _assertTypeStr(type, expected);
    }

    assertLocalFunctionType('f0', 'int Function()');
    assertLocalFunctionType('f1', 'Future<int> Function()');

    assertLocalFunctionType('f2', 'int Function()');
    assertLocalFunctionType('f3', 'Future<int> Function()');
    assertLocalFunctionType('f4', 'Iterable<int> Function()');
    assertLocalFunctionType('f5', 'Stream<int> Function()');

    assertLocalFunctionType('f6', 'num Function()');

    // Recursive cases: these infer in declaration order.
    assertLocalFunctionType('f7', 'dynamic Function()');
    assertLocalFunctionType('f8', 'dynamic Function()');
    assertLocalFunctionType('f9', 'Stream<int> Function()');
  }

  test_inferParameterType_setter_fromField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C extends D {
  set foo(x) {}
}
class D {
  int foo;
//    ^^^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'foo' must be initialized.
}
''');
    var f = result.libraryElement.getClass('C')!.setters[0];
    _assertTypeStr(f.type, 'void Function(int)');
  }

  test_inferParameterType_setter_fromSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C extends D {
  set foo(x) {}
}
class D {
  set foo(int x) {}
}
''');
    var f = result.libraryElement.getClass('C')!.setters[0];
    _assertTypeStr(f.type, 'void Function(int)');
  }

  test_inferred_nonstatic_field_depends_on_static_field_complex() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static var x = 'x';
  var y = {
    'a': {'b': 'c'},
    'd': {'e': x}
  };
}
''');
    var x = result.libraryElement.getClass('C')!.fields[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'String');
    var y = result.libraryElement.getClass('C')!.fields[1];
    expect(y.name, 'y');
    _assertTypeStr(y.type, 'Map<String, Map<String, String>>');
  }

  test_inferred_nonstatic_field_depends_on_toplevel_var_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
var x = 'x';
class C {
  var y = x;
}
''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'String');
    var y = result.libraryElement.getClass('C')!.fields[0];
    expect(y.name, 'y');
    _assertTypeStr(y.type, 'String');
  }

  test_inferredInitializingFormalChecksDefaultValue() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  var x = 1;
  Foo([this.x = "1"]);
//              ^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_inferredType_blockClosure_noArgs_noReturn() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var f = () {};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'f' isn't used.
}
''');

    var f = result.findElement.localVar('f');
    _assertTypeStr(f.type, 'Null Function()');
  }

  test_inferredType_cascade() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int a;
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'a' must be initialized.
  List<int> b;
//          ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'b' must be initialized.
  void m() {}
}
var v = new A()..a = 1..b.add(2)..m();
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'A');
  }

  test_inferredType_customBinaryOp() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool operator*(C other) => true;
}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
var x = c*c;
''');
    var x = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customBinaryOp_viaInterface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  bool operator*(C other) => true;
}
abstract class C implements I {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
var x = c*c;
''');
    var x = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customIndexOp() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool operator[](int index) => true;
}
main() {
  C c;
  var x = c[0];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'c' must be assigned before it can be used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customIndexOp_viaInterface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  bool operator[](int index) => true;
}
abstract class C implements I {}
main() {
  C c;
  var x = c[0];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'c' must be assigned before it can be used.
}
''');

    var x = result.findElement.localVar('x');
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customUnaryOp() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool operator-() => true;
}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
var x = -c;
''');
    var x = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customUnaryOp_viaInterface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  bool operator-() => true;
}
abstract class C implements I {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
var x = -c;
''');
    var x = result.libraryElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_extractMethodTearOff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool g() => true;
}
C f() => null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'C'.
var x = f().g;
''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool Function()');
  }

  test_inferredType_extractMethodTearOff_viaInterface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'C'.
var x = f().g;
''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool Function()');
  }

  test_inferredType_fromTopLevelExecutableTearoff() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = print;
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'void Function(Object?)');
  }

  test_inferredType_invokeMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  bool g() => true;
}
C f() => null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'C'.
var x = f().g();
''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_invokeMethod_viaInterface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
//       ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'C'.
var x = f().g();
''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_isEnum() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { v1 }
final x = E.v1;
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'E');
  }

  test_inferredType_isEnumValues() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E { v1 }
final x = E.values;
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'List<E>');
  }

  test_inferredType_isTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef void F();
final x = <String, F>{};
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<String, void Function()>');
  }

  test_inferredType_isTypedef_parameterized() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef T F<T>();
final x = <String, F<int>>{};
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<String, int Function()>');
  }

  test_inferredType_usesSyntheticFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() => null;
//         ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
String g() => null;
//            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'String'.
var v = [f, g];
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function()>');
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f(int x(String y)) => null;
//                        ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
String g(int x(String y)) => null;
//                           ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'String'.
var v = [f, g];
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function(int Function(String))>');
  }

  test_inferredType_usesSyntheticFunctionType_namedParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f({int x}) => null;
//         ^
// [diag.missingDefaultValueForParameter] The parameter 'x' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
String g({int x}) => null;
//            ^
// [diag.missingDefaultValueForParameter] The parameter 'x' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'String'.
var v = [f, g];
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function({int x})>');
  }

  test_inferredType_usesSyntheticFunctionType_positionalParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f([int x]) => null;
//         ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'x' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
String g([int x]) => null;
//            ^
// [diag.missingDefaultValueForParameterPositional] The parameter 'x' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
//                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'String'.
var v = [f, g];
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function([int])>');
  }

  test_inferredType_usesSyntheticFunctionType_requiredParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f(int x) => null;
//              ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'int'.
String g(int x) => null;
//                 ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'g' because it has a return type of 'String'.
var v = [f, g];
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function(int)>');
  }

  test_inferredType_viaClosure_multipleLevelsOfNesting() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static final f = (bool b) =>
      (int i) => {i: b};
}
''');
    var f = result.libraryElement.getClass('C')!.fields[0];
    _assertTypeStr(f.type, 'Map<int, bool> Function(int) Function(bool)');
  }

  test_inferredType_viaClosure_typeDependsOnArgs() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static final f = (bool b) => b;
}
''');
    var f = result.libraryElement.getClass('C')!.fields[0];
    _assertTypeStr(f.type, 'bool Function(bool)');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_field() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static final f = (bool b) => 1;
}
''');
    var f = result.libraryElement.getClass('C')!.fields[0];
    _assertTypeStr(f.type, 'int Function(bool)');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics('''
final f = (bool b) => 1;
''');
    var f = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(f.type, 'int Function(bool)');
  }

  test_inferReturnOfStatementLambda() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26139
    await resolveTestCodeWithDiagnostics(r'''
List<String> strings() {
  var stuff = [].expand((i) {
    return <String>[];
  });
  return stuff.toList();
}
  ''');
  }

  test_inferStaticsTransitively() async {
    newFile('$testPackageLibPath/b.dart', '''
final b1 = 2;
''');

    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
import 'b.dart';
final a1 = m2;
class A {
  static final a2 = b1;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
final m1 = a1;
final m2 = A.a2;

foo() {
  // ignore:unused_local_variable
  int i;
  i = m1;
}
''');
  }

  test_inferStaticsTransitively2() async {
    await resolveTestCodeWithDiagnostics(r'''
const x1 = 1;
final x2 = 1;
final y1 = x1;
final y2 = x2;

foo() {
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  i = y1;
  i = y2;
}
''');
  }

  test_inferStaticsTransitively3() async {
    newFile('$testPackageLibPath/a.dart', '''
const a1 = 3;
const a2 = 4;
class A {
  static const a3 = null;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show a1, A;
import 'a.dart' as p show a2, A;
const t1 = 1;
const t2 = t1;
const t3 = a1;
const t4 = p.a2;
const t5 = A.a3;
const t6 = p.A.a3;

foo() {
  // ignore:unused_local_variable
  int i;
  i = t1;
  i = t2;
  i = t3;
  i = t4;
}
''');
  }

  test_inferStaticsWithMethodInvocations() async {
    newFile('$testPackageLibPath/a.dart', '''
m3(String a, String b, [a1,a2]) {}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
class T {
  static final T foo = m1(m2(m3('', '')));
  static T m1(String m) { return null; }
//                               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm1' because it has a return type of 'T'.
  static String m2(e) { return ''; }
}
''');
  }

  test_inferTypeOnOverriddenFields2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 2;
}

class B extends A {
  get x => 3;
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferTypeOnOverriddenFields4() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 2;
}

class B implements A {
  get x => 3;
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferTypeOnVar() async {
    // Error also expected when declared type is `int`.
    await resolveTestCodeWithDiagnostics(r'''
test1() {
  int x = 3;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_inferTypeOnVar2() async {
    await resolveTestCodeWithDiagnostics(r'''
test2() {
  var x = 3;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_inferTypeOnVarFromField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;

  test1() {
    var a = x;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    a = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
    a = 3;
    var b = y;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
    b = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
    b = 4;
    var c = z;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
    c = "hi";
//      ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
    c = 4;
  }

  int y; // field def after use
//    ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'y' must be initialized.
  final z = 42; // should infer `int`
}
''');
  }

  test_inferTypeOnVarFromTopLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 0;

test1() {
  var a = x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  a = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  a = 3;
  var b = y;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  b = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  b = 4;
  var c = z;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
  c = "hi";
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  c = 4;
}

int y = 0; // field def after use
final z = 42; // should infer `int`
''');
  }

  test_inferTypeRegardlessOfDeclarationOrderOrCycles() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';

class B extends A { }
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';
class C extends B {
  get x => null;
//         ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'x' because it has a return type of 'int'.
}
class A {
  int get x => 0;
}
foo() {
  int y = new C().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  String z = new C().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
}
''');
  }

  test_inferTypesOnGenericInstantiations_3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T x = null;
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T'.
  final T w = null;
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T'.
}

class B implements A<int> {
  get x => 3;
  get w => "hello";
//         ^^^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'w' because it has a return type of 'int'.
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//           ^^^^^^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferTypesOnGenericInstantiations_4() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T x;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'x' must be initialized.
}

class B<E> extends A<E> {
  E y;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'y' must be initialized.
  get x => y;
}

foo() {
  int y = new B<String>().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//        ^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
  String z = new B<String>().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferTypesOnGenericInstantiations_5() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class I<E> {
  String m(a, String f(v, E e));
}

abstract class A<E> implements I<E> {
  const A();
  String m(a, String f(v, E e));
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, E e)) { return null; }
//                         ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'String'.
}

foo () {
  int y = new B().m(null, null);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//        ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
//                        ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'dynamic Function(dynamic, dynamic)'.
  String z = new B().m(null, null);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                           ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'dynamic Function(dynamic, dynamic)'.
}
''');
  }

  test_inferTypesOnGenericInstantiations_infer() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T x = null;
//        ^
// [context 1] The member being overridden.
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'T'.
}

class B implements A<int> {
  dynamic get x => 3;
//            ^
// [diag.invalidOverride][context 1] 'B.x' ('dynamic Function()') isn't a valid override of 'A.x' ('int Function()').
}

foo() {
  String y = new B().x;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  int z = new B().x;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_inferTypesOnGenericInstantiationsInLibraryCycle() async {
    // Note: this is a regression test for bug #48.
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
abstract class I<E> {
  A<E> m(a, String f(v, int e));
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

abstract class A<E> implements I<E> {
  const A();

  final E value = null;
//                ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'E'.
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, int e)) { return null; }
//                           ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'm' because it has a return type of 'A<E>'.
}

foo () {
  int y = new B<String>().m(null, null).value;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
//                                ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'dynamic Function(dynamic, int)'.
  String z = new B<String>().m(null, null).value;
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                                   ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'Null' can't be assigned to the parameter type 'dynamic Function(dynamic, int)'.
}
''');
  }

  test_inferTypesOnLoopIndices_forEachLoop() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  int bar = 42;
}

class Bar<T extends Iterable<String>> {
  void foo(T t) {
    for (var i in t) {
      int x = i;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//            ^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
    }
  }
}

class Baz<T, E extends Iterable<T>, S extends E> {
  void foo(S t) {
    for (var i in t) {
      int x = i;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//            ^
// [diag.invalidAssignment] A value of type 'T' can't be assigned to a variable of type 'int'.
      T y = i;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
    }
  }
}

test() {
  var list = <Foo>[];
  for (var x in list) {
    String y = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//             ^
// [diag.invalidAssignment] A value of type 'Foo' can't be assigned to a variable of type 'String'.
  }

  for (dynamic x in list) {
    String y = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  for (String x in list) {
//                 ^^^^
// [diag.forInOfInvalidElementType] The type 'List<Foo>' used in the 'for' loop must implement 'Iterable' with a type argument that can be assigned to 'String'.
    String y = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  var z;
  for(z in list) {
    String y = z;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  Iterable iter = list;
  for (Foo x in iter) {
    var y = x;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  dynamic iter2 = list;
  for (Foo x in iter2) {
    var y = x;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  var map = <String, Foo>{};
  // Error: map must be an Iterable.
  for (var x in map) {
//              ^^^
// [diag.forInOfInvalidType] The type 'Map<String, Foo>' used in the 'for' loop must implement 'Iterable'.
    String y = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }

  // We're not properly inferring that map.keys is an Iterable<String>
  // and that x is a String.
  for (var x in map.keys) {
    String y = x;
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  }
}
''');
  }

  test_inferTypesOnLoopIndices_forLoopWithInference() async {
    await resolveTestCodeWithDiagnostics(r'''
test() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'j' isn't used.
  }
}
''');
  }

  test_inferVariableVoid() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {}
var x = f();
  ''');
    var x = result.libraryElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'void');
  }

  test_lambdaDoesNotHavePropagatedTypeHint() async {
    await resolveTestCodeWithDiagnostics(r'''
List<String> getListOfString() => const <String>[];

void foo() {
  List myList = getListOfString();
  myList.map((type) => 42);
}

void bar() {
  var list;
  try {
    list = <String>[];
  } catch (_) {
    return;
  }
  list.map((value) => '$value');
}
  ''');
  }

  test_listLiterals() async {
    await resolveTestCodeWithDiagnostics(r'''
test1() {
  var x = [1, 2, 3];
  x.add('hi');
//      ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  x.add(4.0);
//      ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  x.add(4);
  List<num> y = x;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
test2() {
  var x = [1, 2.0, 3];
  x.add('hi');
//      ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
  x.add(4.0);
  List<int> y = x;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
}
''');
  }

  test_listLiterals_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
var x1 = [1, 2, 3];
test1() {
  x1.add('hi');
//       ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  x1.add(4.0);
//       ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  x1.add(4);
  List<num> y = x1;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
var x2 = [1, 2.0, 3];
test2() {
  x2.add('hi');
//       ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
  x2.add(4.0);
  List<int> y = x2;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^^
// [diag.invalidAssignment] A value of type 'List<num>' can't be assigned to a variable of type 'List<int>'.
}
''');
  }

  test_listLiteralsCanInferNull_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = [null];
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'List<Null>');
  }

  test_listLiteralsCanInferNullBottom() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test1() {
  var x = [null];
  x.add(42);
//      ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Null'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'List<Null>');
  }

  test_mapLiterals() async {
    await resolveTestCodeWithDiagnostics(r'''
test1() {
  var x = { 1: 'x', 2: 'y' };
  x[3] = 'z';
  x['hi'] = 'w';
//  ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  x[4.0] = 'u';
//  ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  x[3] = 42;
//       ^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  Map<num, String> y = x;
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}

test2() {
  var x = { 1: 'x', 2: 'y', 3.0: new RegExp('.') };
  x[3] = 'z';
  x['hi'] = 'w';
//  ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
  x[4.0] = 'u';
  x[3] = 42;
//       ^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'Pattern'.
  Pattern p = null;
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Pattern'.
  x[2] = p;
  Map<int, String> y = x;
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//                     ^
// [diag.invalidAssignment] A value of type 'Map<num, Pattern>' can't be assigned to a variable of type 'Map<int, String>'.
}
''');
  }

  test_mapLiterals_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
var x1 = { 1: 'x', 2: 'y' };
test1() {
  x1[3] = 'z';
  x1['hi'] = 'w';
//   ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
  x1[4.0] = 'u';
//   ^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
  x1[3] = 42;
//        ^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
  Map<num, String> y = x1;
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}

var x2 = { 1: 'x', 2: 'y', 3.0: new RegExp('.') };
test2() {
  x2[3] = 'z';
  x2['hi'] = 'w';
//   ^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'num'.
  x2[4.0] = 'u';
  x2[3] = 42;
//        ^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'Pattern'.
  Pattern p = null;
//            ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'Pattern'.
  x2[2] = p;
  Map<int, String> y = x2;
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//                     ^^
// [diag.invalidAssignment] A value of type 'Map<num, Pattern>' can't be assigned to a variable of type 'Map<int, String>'.
}
''');
  }

  test_mapLiteralsCanInferNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
test1() {
  var x = { null: null };
  x[3] = 'z';
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'Null'.
//       ^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'Null'.
}
''');

    var x = result.findElement.localVar('x');
    _assertTypeStr(x.type, 'Map<Null, Null>');
  }

  test_mapLiteralsCanInferNull_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = { null: null };
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<Null, Null>');
  }

  test_methodCall_withTypeArguments_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  D<T> f<T>() => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'D<T>'.
}
class D<T> {}
var f = new C().f<int>();
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_instanceMethod_identifierSequence() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  D<T> f<T>() => null;
//               ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'D<T>'.
}
class D<T> {}
C c;
//^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'c' must be initialized.
var f = c.f<int>();
''');
    var v = result.libraryElement.topLevelVariables[1];
    expect(v.name, 'f');
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static D<T> f<T>() => null;
//                      ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'D<T>'.
}
class D<T> {}
var f = C.f<int>();
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
D<T> f<T>() => null;
//             ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'f' because it has a return type of 'D<T>'.
class D<T> {}
var g = f<int>();
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_noErrorWhenDeclaredTypeIsNumAndAssignedNull() async {
    await resolveTestCodeWithDiagnostics(r'''
test1() {
  num x = 3;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x = null;
//    ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'num'.
}
''');
  }

  test_nullCoalescingOperator() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26552
    await resolveTestCodeWithDiagnostics(r'''
main() {
  List<int> x;
  var y = x ?? [];
//        ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
//          ^^^^^
// [diag.deadCode] Dead code.
//             ^^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  List<int> z = y;
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_nullCoalescingOperator2() async {
    // Don't do anything if we already have a context type.
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  List<int> x;
  List<num> y = x ?? [];
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
//                ^^^^^
// [diag.deadCode] Dead code.
//                   ^^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');

    var y = result.findElement.localVar('y');
    _assertTypeStr(y.type, 'List<num>');
  }

  test_nullLiteralShouldNotInferAsBottom() async {
    // Regression test for https://github.com/dart-lang/dev_compiler/issues/47
    await resolveTestCodeWithDiagnostics(r'''
var h = null;
void foo(int f(Object _)) {}

main() {
  var f = (Object x) => null;
  String y = f(42);
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//           ^^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'String'.

  f = (x) => 'hello';
//           ^^^^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'String' isn't returnable from a 'Null' function, as required by the closure's context.

  var g = null;
  g = 'hello';
  (g.foo());

  h = 'hello';
  (h.foo());

  foo((x) => null);
//           ^^^^
// [diag.returnOfInvalidTypeFromClosure] The returned type 'Null' isn't returnable from a 'int' function, as required by the closure's context.
  foo((x) => throw "not implemented");
}
''');
  }

  test_propagateInferenceToFieldInClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 2;
}

test() {
  var a = new A();
  A b = a;                      // doesn't require down cast
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  print(a.x);     // doesn't require dynamic invoke
  print(a.x + 2); // ok to use in bigger expression
}
''');
  }

  test_propagateInferenceToFieldInClassDynamicWarnings() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 2;
}

test() {
  dynamic a = new A();
  A b = a;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
  print(a.x);
  print((a.x) + 2);
}
''');
  }

  test_propagateInferenceTransitively() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 2;
}

test5() {
  var a1 = new A();
  a1.x = "hi";
//       ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.

  A a2 = new A();
  a2.x = "hi";
//       ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
}
''');
  }

  test_propagateInferenceTransitively2() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int x = 42;
}

class B {
  A a = new A();
}

class C {
  B b = new B();
}

class D {
  C c = new C();
}

void main() {
  var d1 = new D();
  print(d1.c.b.a.x);

  D d2 = new D();
  print(d2.c.b.a.x);
}
''');
  }

  test_referenceToTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef void F();
final x = F;
''');
    var x = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Type');
  }

  test_refineBinaryExpressionType_typeParameter_T_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends num> {
  T a;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'a' must be initialized.

  void op(double b) {
    double r1 = a + b;
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'r1' isn't used.
    double r2 = a - b;
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'r2' isn't used.
    double r3 = a * b;
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'r3' isn't used.
    double r4 = a / b;
//         ^^
// [diag.unusedLocalVariable] The value of the local variable 'r4' isn't used.
  }
}
''');
  }

  test_refineBinaryExpressionType_typeParameter_T_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends num> {
  T a;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'a' must be initialized.

  void op(int b) {
    T r1 = a + b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r1' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    T r2 = a - b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r2' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    T r3 = a * b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r3' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
  }

  void opEq(int b) {
    a += b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    a -= b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    a *= b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
  }
}
''');
  }

  test_refineBinaryExpressionType_typeParameter_T_T() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends num> {
  T a;
//  ^
// [diag.notInitializedNonNullableInstanceField] Non-nullable instance field 'a' must be initialized.

  void op(T b) {
    T r1 = a + b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r1' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    T r2 = a - b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r2' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    T r3 = a * b;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'r3' isn't used.
//         ^^^^^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
  }

  void opEq(T b) {
    a += b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    a -= b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
    a *= b;
//       ^
// [diag.invalidAssignment] A value of type 'num' can't be assigned to a variable of type 'T'.
  }
}
''');
  }

  test_staticMethod_tearoff() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const v = C.f;
class C {
  static int f(String s) => null;
//                          ^^^^
// [diag.returnOfInvalidTypeFromMethod] A value of type 'Null' can't be returned from the method 'f' because it has a return type of 'int'.
}
''');
    var v = result.libraryElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'int Function(String)');
  }

  test_unsafeBlockClosureInference_closureCall() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26962
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = ((x) => 1.0)(() { return 1; });
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitDynamicParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C(T x());
}
var v = new C<dynamic>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<dynamic>');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  C(T x());
}
var v = new C<int>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_implicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  C(T x());
}
main() {
  var v = new C(
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    () {
      return 1;
    });
}
''');

    var v = result.findElement.localVar('v');
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_noTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  C(x());
}
var v = new C(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<dynamic>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  // Failing without null safety.
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr1() async {
    // Note: (f<dynamic>) is not a valid syntax.
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f<dynamic>)(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<dynamic>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<int>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  // @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/25824')
  // Test passes because of timeout.
  // Failing without null safety.
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr1() async {
    // Note: (f<int>) is not a valid syntax.
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f<int>)(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2() async {
    var result = await resolveTestCodeWithDiagnostics('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<int>(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = f(
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    () {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = (f)(
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    () {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = f(() { return 1; });
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
double f(x) => 1.0;
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam_viaExpr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = (f)(() { return 1; });
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
double f(x) => 1.0;
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_inList_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = <dynamic>[() { return 1; }];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_inList_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef int F();
main() {
  var v = <F>[() { return 1; }];
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int Function()>');
  }

  test_unsafeBlockClosureInference_inList_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = [
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    () {
      return 1;
    }];
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int Function()>');
  }

  test_unsafeBlockClosureInference_inMap_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = <int, dynamic>{1: () { return 1; }};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, dynamic>');
  }

  test_unsafeBlockClosureInference_inMap_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef int F();
main() {
  var v = <int, F>{1: () { return 1; }};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, int Function()>');
  }

  test_unsafeBlockClosureInference_inMap_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = {
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    1: () {
      return 1;
    }};
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, int Function()>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitDynamicParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<dynamic>(() { return 1; });
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<int>(() { return 1; });
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_implicitTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f(
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    () {
      return 1;
    });
}
''');

    var v = result.findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_noTypeParam() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  double f(x) => 1.0;
}
var v = new C().f(() { return 1; });
''');
    var v = result.libraryElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'double');
  }

  test_voidReturnTypeEquivalentToDynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
T run<T>(T f()) {
  print("running");
  var t = f();
  print("done running");
  return t;
}


void printRunning() { print("running"); }
var x = run<dynamic>(printRunning);
var y = run(printRunning);

main() {
  void printRunning() { print("running"); }
  var x = run<dynamic>(printRunning);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  var y = run(printRunning);
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
  x = 123;
  x = 'hi';
  y = 123;
  y = 'hi';
}
''');

    var x = result.libraryElement.topLevelVariables[0];
    var y = result.libraryElement.topLevelVariables[1];
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'void');
  }

  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }
}
