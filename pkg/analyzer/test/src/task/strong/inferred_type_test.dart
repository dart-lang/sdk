// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.strong.inferred_type_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../utils.dart';
import 'strong_test_helper.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferredTypeTest);
    defineReflectiveTests(InferredTypeTest_Driver);
  });
}

abstract class InferredTypeMixin {
  /// Extra top-level errors if needed due to being analyze multiple times.
  bool get hasExtraTaskModelPass => true;

  /**
   * If `true` then types of local elements may be checked.
   */
  bool get mayCheckTypesOfLocals;

  /**
   * Add a new file with the given [name] and [content].
   */
  void addFile(String content, {String name: '/main.dart'});

  /**
   * Add the file, process it (resolve, validate, etc) and return the resolved
   * unit.
   */
  Future<CompilationUnit> checkFile(String content,
      {bool declarationCasts: true,
      bool implicitCasts: true,
      bool implicitDynamic: true,
      List<String> nonnullableTypes: AnalysisOptionsImpl.NONNULLABLE_TYPES,
      bool superMixins: false});

  /**
   * Add the file, process it (resolve, validate, etc) and return the resolved
   * unit element.
   */
  Future<CompilationUnitElement> checkFileElement(String content);

  test_asyncClosureReturnType_flatten() async {
    var mainUnit = await checkFileElement('''
import 'dart:async';
Future<int> futureInt = null;
var f = () => futureInt;
var g = () async => futureInt;
''');
    var futureInt = mainUnit.topLevelVariables[0];
    expect(futureInt.name, 'futureInt');
    expect(futureInt.type.toString(), 'Future<int>');
    var f = mainUnit.topLevelVariables[1];
    expect(f.name, 'f');
    expect(f.type.toString(), '() → Future<int>');
    var g = mainUnit.topLevelVariables[2];
    expect(g.name, 'g');
    expect(g.type.toString(), '() → Future<int>');
  }

  test_asyncClosureReturnType_future() async {
    var mainUnit = await checkFileElement('var f = () async => 0;');
    var f = mainUnit.topLevelVariables[0];
    expect(f.name, 'f');
    expect(f.type.toString(), '() → Future<int>');
  }

  test_asyncClosureReturnType_futureOr() async {
    var mainUnit = await checkFileElement('''
import 'dart:async';
FutureOr<int> futureOrInt = null;
var f = () => futureOrInt;
var g = () async => futureOrInt;
''');
    var futureOrInt = mainUnit.topLevelVariables[0];
    expect(futureOrInt.name, 'futureOrInt');
    expect(futureOrInt.type.toString(), 'FutureOr<int>');
    var f = mainUnit.topLevelVariables[1];
    expect(f.name, 'f');
    expect(f.type.toString(), '() → FutureOr<int>');
    var g = mainUnit.topLevelVariables[2];
    expect(g.name, 'g');
    expect(g.type.toString(), '() → Future<int>');
  }

  test_blockBodiedLambdas_async_allReturnsAreFutures() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return new Future<double>.value(2.0);
    }
  };
  Future<num> g = f();
  Future<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Future<num>');
  }

  test_blockBodiedLambdas_async_allReturnsAreValues() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
    if (new Random().nextBool()) {
      return 1;
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
  Future<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Future<num>');
  }

  test_blockBodiedLambdas_async_mixOfValuesAndFutures() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
  Future<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Future<num>');
  }

  test_blockBodiedLambdas_asyncStar() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async* {
    yield 1;
    Stream<double> s;
    yield* s;
  };
  Stream<num> g = f();
  Stream<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Stream<num>');
  }

  test_blockBodiedLambdas_basic() async {
    await checkFileElement(r'''
test1() {
  List<int> o;
  var y = o.map(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(x) { return x + 1; });
  Iterable<int> z = y;
}
''');
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
main() {
  String f() => null;
  var g = f;
  g = /*info:INFERRED_TYPE_CLOSURE*/() { return /*error:RETURN_OF_INVALID_TYPE*/1; };
}
''');
    var g = findLocalVariable(unit, 'g');
    expect(g.type.toString(), '() → String');
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference_topLevel() async {
    var unit = await checkFileElement(r'''
String f() => null;
var g = f;
''');
    var g = unit.topLevelVariables[0];
    expect(g.type.toString(), '() → String');
  }

  test_blockBodiedLambdas_inferBottom_async() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
main() async {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async { return null; };
  Future y = f();
  Future<String> z = f();
  String s = await f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Future<Null>');
  }

  test_blockBodiedLambdas_inferBottom_asyncStar() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
import 'dart:async';
main() async {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() async* { yield null; };
  Stream y = f();
  Stream<String> z = f();
  String s = await f().first;
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Stream<Null>');
  }

  test_blockBodiedLambdas_inferBottom_sync() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
var h = null;
void foo(int g(Object _)) {}

main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/(Object x) { return null; };
  String y = f(42);

  f = /*error:INVALID_CAST_FUNCTION_EXPR, info:INFERRED_TYPE_CLOSURE*/(x) => 'hello';

  foo(/*info:INFERRED_TYPE_CLOSURE,
        info:INFERRED_TYPE_CLOSURE*/(x) { return null; });
  foo(/*info:INFERRED_TYPE_CLOSURE,
        info:INFERRED_TYPE_CLOSURE*/(x) { throw "not implemented"; });
}
''');

    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '(Object) → Null');
  }

  test_blockBodiedLambdas_inferBottom_syncStar() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() sync* { yield null; };
  Iterable y = f();
  Iterable<String> z = f();
  String s = f().first;
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Iterable<Null>');
  }

  test_blockBodiedLambdas_LUB() async {
    await checkFileElement(r'''
import 'dart:math' show Random;
test2() {
  List<num> o;
  var y = o.map(/*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*/(x) {
    if (new Random().nextBool()) {
      return x.toInt() + 1;
    } else {
      return x.toDouble();
    }
  });
  Iterable<num> w = y;
  Iterable<int> z = /*info:ASSIGNMENT_CAST*/y;
}
''');
  }

  test_blockBodiedLambdas_nestedLambdas() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    // Original feature request: https://github.com/dart-lang/sdk/issues/25487
    var unit = await checkFile(r'''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() {
    return /*info:INFERRED_TYPE_CLOSURE*/(int x) { return 2.0 * x; };
  };
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → (int) → double');
  }

  test_blockBodiedLambdas_noReturn() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
test1() {
  List<int> o;
  var y = o.map(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(x) { });
  Iterable<int> z = y;
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.type.toString(), 'Iterable<Null>');
  }

  test_blockBodiedLambdas_syncStar() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() sync* {
    yield 1;
    yield* /*info:INFERRED_TYPE_LITERAL*/[3, 4.0];
  };
  Iterable<num> g = f();
  Iterable<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Iterable<num>');
  }

  test_bottom() async {
    // When a type is inferred from the expression `null`, the inferred type is
    // `dynamic`, but the inferred type of the initializer is `bottom`.
    // TODO(paulberry): Is this intentional/desirable?
    var mainUnit = await checkFileElement('''
var v = null;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'dynamic');
    expect(v.initializer.type.toString(), '() → Null');
  }

  test_bottom_inClosure() async {
    // When a closure's return type is inferred from the expression `null`, the
    // inferred type is `dynamic`.
    var mainUnit = await checkFileElement('''
var v = () => null;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '() → dynamic');
    expect(v.initializer.type.toString(), '() → () → dynamic');
  }

  @failingTest
  test_circularReference_viaClosures() async {
    var mainUnit = await checkFileElement('''
var x = () => /*error:TOP_LEVEL_CYCLE*/y;
var y = () => /*error:TOP_LEVEL_CYCLE*/x;
''');
    var x = mainUnit.topLevelVariables[0];
    var y = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    expect(x.type.toString(), 'dynamic');
    expect(y.type.toString(), 'dynamic');
  }

  @failingTest
  test_circularReference_viaClosures_initializerTypes() async {
    var mainUnit = await checkFileElement('''
var x = () => /*error:TOP_LEVEL_CYCLE*/y;
var y = () => /*error:TOP_LEVEL_CYCLE*/x;
''');
    var x = mainUnit.topLevelVariables[0];
    var y = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    expect(x.initializer.returnType.toString(), '() → dynamic');
    expect(y.initializer.returnType.toString(), '() → dynamic');
  }

  test_conflictsCanHappen() async {
    await checkFileElement('''
class I1 {
  int x;
}
class I2 extends I1 {
  int y;
}

class A {
  final I1 a = null;
}

class B {
  final I2 a = null;
}

class C1 implements A, B {
  /*error:INVALID_METHOD_OVERRIDE*/get a => null;
}

// Still ambiguous
class C2 implements B, A {
  /*error:INVALID_METHOD_OVERRIDE*/get a => null;
}
''');
  }

  test_conflictsCanHappen2() async {
    await checkFileElement('''
class I1 {
  int x;
}
class I2 {
  int y;
}

class I3 implements I1, I2 {
  int x;
  int y;
}

class A {
  final I1 a = null;
}

class B {
  final I2 a = null;
}

class C1 implements A, B {
  I3 get a => null;
}

class C2 implements A, B {
  /*error:INVALID_METHOD_OVERRIDE*/get a => null;
}
''');
  }

  test_constructors_downwardsWithConstraint() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26431
    await checkFileElement(r'''
class A {}
class B extends A {}
class Foo<T extends A> {}
void main() {
  Foo<B> foo = /*info:INFERRED_TYPE_ALLOCATION*/new Foo();
}
''');
  }

  test_constructors_inferenceFBounded() async {
    var errors = 'error:COULD_NOT_INFER,error:COULD_NOT_INFER';
//    if (hasExtraTaskModelPass) errors = '$errors,$errors';
    var unit = await checkFile('''
class Clonable<T> {}

class Pair<T extends Clonable<T>, U extends Clonable<U>> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair._();
  Pair<U, T> get reversed => /*info:INFERRED_TYPE_ALLOCATION*/new Pair(u, t);
}

main() {
  final x = new /*$errors*/Pair._();
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'Pair<Clonable<dynamic>, Clonable<dynamic>>');
  }

  test_constructors_inferFromArguments() async {
    var unit = await checkFile('''
class C<T> {
  T t;
  C(this.t);
}

main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C(42);

  num y;
  C<int> c_int = /*info:INFERRED_TYPE_ALLOCATION*/new C(/*info:DOWN_CAST_IMPLICIT*/y);

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = /*info:INFERRED_TYPE_ALLOCATION*/new C(123);
  C<num> c_num2 = (/*info:INFERRED_TYPE_ALLOCATION*/new C(456))
      ..t = 1.0;

  // Down't infer from explicit dynamic.
  var c_dynamic = new C<dynamic>(42);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    expect(findLocalVariable(unit, 'x').type.toString(), 'C<int>');
    expect(findLocalVariable(unit, 'c_int').type.toString(), 'C<int>');
    expect(findLocalVariable(unit, 'c_num').type.toString(), 'C<num>');
    expect(findLocalVariable(unit, 'c_dynamic').type.toString(), 'C<dynamic>');
  }

  test_constructors_inferFromArguments_argumentNotAssignable() async {
    var unit = await checkFile('''
class A {}

typedef T F<T>();

class C<T extends A> {
  C(F<T> f);
}

class NotA {}
NotA myF() => null;

main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new /*error:COULD_NOT_INFER*/C(myF);
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<NotA>');
  }

  test_constructors_inferFromArguments_const() async {
    var unit = await checkFile('''
class C<T> {
  final T t;
  const C(this.t);
}

main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/const C(42);
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_inferFromArguments_constWithUpperBound() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26993
    await checkFileElement('''
class C<T extends num> {
  final T x;
  const C(this.x);
}
class D<T extends num> {
  const D();
}
void f() {
  const c = /*info:INFERRED_TYPE_ALLOCATION*/const C(0);
  C<int> c2 = c;
  const D<int> d = /*info:INFERRED_TYPE_ALLOCATION*/const D();
}
''');
  }

  test_constructors_inferFromArguments_downwardsFromConstructor() {
    return checkFileElement(r'''
class C<T> { C(List<T> list); }

main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C(/*info:INFERRED_TYPE_LITERAL*/[123]);
  C<int> y = x;

  var a = new C<dynamic>([123]);
  // This one however works.
  var b = new C<Object>(/*info:INFERRED_TYPE_LITERAL*/[123]);
}
''');
  }

  test_constructors_inferFromArguments_factory() async {
    var unit = await checkFile('''
class C<T> {
  T t;

  C._();

  factory C(T t) {
    var c = new C<T>._();
    c.t = t;
    return c;
  }
}


main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C(42);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_inferFromArguments_factory_callsConstructor() async {
    await checkFileElement(r'''
class A<T> {
  A<T> f = /*info:INFERRED_TYPE_ALLOCATION*/new A();
  A();
  factory A.factory() => /*info:INFERRED_TYPE_ALLOCATION*/new A();
  A<T> m() => /*info:INFERRED_TYPE_ALLOCATION*/new A();
}
''');
  }

  test_constructors_inferFromArguments_named() async {
    var unit = await checkFile('''
class C<T> {
  T t;
  C.named(List<T> t);
}


main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C.named(<int>[]);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_inferFromArguments_namedFactory() async {
    var unit = await checkFile('''
class C<T> {
  T t;
  C();

  factory C.named(T t) {
    var c = new C<T>();
    c.t = t;
    return c;
  }
}


main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C.named(42);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_inferFromArguments_redirecting() async {
    var unit = await checkFile('''
class C<T> {
  T t;
  C(this.t);
  C.named(List<T> t) : this(t[0]);
}


main() {
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C.named(<int>[42]);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_inferFromArguments_redirectingFactory() async {
    var unit = await checkFile('''
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
  var x = /*info:INFERRED_TYPE_ALLOCATION*/new C(42);
  x.t = /*error:INVALID_ASSIGNMENT*/'hello';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'C<int>');
  }

  test_constructors_reverseTypeParameters() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26990
    await checkFileElement('''
class Pair<T, U> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair<U, T> get reversed => /*info:INFERRED_TYPE_ALLOCATION*/new Pair(u, t);
}
''');
  }

  test_constructors_tooManyPositionalArguments() async {
    var unit = await checkFile(r'''
class A<T> {}
main() {
  var a = new A/*error:EXTRA_POSITIONAL_ARGUMENTS*/(42);
}
''');
    var a = findLocalVariable(unit, 'a');
    expect(a.type.toString(), 'A<dynamic>');
  }

  test_doNotInferOverriddenFieldsThatExplicitlySayDynamic_infer() async {
    await checkFileElement('''
class A {
  final int x = 2;
}

class B implements A {
  /*error:INVALID_METHOD_OVERRIDE*/dynamic get x => 3;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/new B().x;
  int z = /*info:DYNAMIC_CAST*/new B().x;
}
''');
  }

  test_dontInferFieldTypeWhenInitializerIsNull() async {
    await checkFileElement('''
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
  y = /*error:INVALID_ASSIGNMENT*/"hi";
  A.x = "hi";
  A.y = /*error:INVALID_ASSIGNMENT*/"hi";
  new A().x2 = "hi";
  new A().y2 = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_dontInferTypeOnDynamic() async {
    await checkFileElement('''
test() {
  dynamic x = 3;
  x = "hi";
}
''');
  }

  test_dontInferTypeWhenInitializerIsNull() async {
    await checkFileElement('''
test() {
  var x = null;
  x = "hi";
  x = 3;
}
''');
  }

  test_downwardInference_fixes_noUpwardsErrors() async {
    await checkFileElement(r'''
import 'dart:math';
// T max<T extends num>(T x, T y);
main() {
  num x;
  dynamic y;

  num a = max(x, /*info:DYNAMIC_CAST*/y);
  Object b = max(x, /*info:DYNAMIC_CAST*/y);
  dynamic c = /*error:COULD_NOT_INFER*/max(x, y);
  var d = /*error:COULD_NOT_INFER*/max(x, y);
}''');
  }

  test_downwardInference_miscellaneous() async {
    await checkFileElement('''
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
    f(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/{y: x}]);
  }
  {
    int f(int x) => 0;
    A<int> a = /*info:INFERRED_TYPE_ALLOCATION*/new A(f);
  }
}
''');
  }

  test_downwardsInference_insideTopLevel() async {
    await checkFileElement('''
class A {
  B<int> b;
}

class B<T> {
  B(T x);
}

var t1 = new A()..b = /*info:INFERRED_TYPE_ALLOCATION*/new B(1);
var t2 = <B<int>>[/*info:INFERRED_TYPE_ALLOCATION*/new B(2)];
var t3 = /*info:INFERRED_TYPE_LITERAL*/[
            /*info:INFERRED_TYPE_ALLOCATION*/new B(3)
         ];
''');
  }

  test_downwardsInferenceAnnotations() async {
    await checkFileElement('''
class Foo {
  const Foo(List<String> l);
  const Foo.named(List<String> l);
}
@Foo(/*info:INFERRED_TYPE_LITERAL*/const [])
class Bar {}
@Foo.named(/*info:INFERRED_TYPE_LITERAL*/const [])
class Baz {}
''');
  }

  test_downwardsInferenceAssignmentStatements() async {
    await checkFileElement('''
void main() {
  List<int> l;
  l = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
  l = (l = /*info:INFERRED_TYPE_LITERAL*/[1]);
}
''');
  }

  test_downwardsInferenceAsyncAwait() async {
    await checkFileElement('''
import 'dart:async';
Future test() async {
  dynamic d;
  List<int> l0 = await /*info:INFERRED_TYPE_LITERAL*/[/*info:DYNAMIC_CAST*/d];
  List<int> l1 = await /*info:INFERRED_TYPE_ALLOCATION*/new Future.value(
      /*info:INFERRED_TYPE_LITERAL*/[/*info:DYNAMIC_CAST*/d]);
}
''');
  }

  test_downwardsInferenceForEach() async {
    await checkFileElement('''
import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

Future main() async {
  for(int x in /*info:INFERRED_TYPE_LITERAL*/[1, 2, 3]) {}
  await for(int x in /*info:INFERRED_TYPE_ALLOCATION*/new MyStream()) {}
}
''');
  }

  test_downwardsInferenceInitializingFormalDefaultFormal() async {
    await checkFileElement('''
typedef T Function2<S, T>([S x]);
class Foo {
  List<int> x;
  Foo([this.x = /*info:INFERRED_TYPE_LITERAL*/const [1]]);
  Foo.named([List<int> x = /*info:INFERRED_TYPE_LITERAL*/const [1]]);
}
void f([List<int> l = /*info:INFERRED_TYPE_LITERAL*/const [1]]) {}
// We do this inference in an early task but don't preserve the infos.
Function2<List<int>, String> g = /*pass should be info:INFERRED_TYPE_CLOSURE*/([llll = /*info:INFERRED_TYPE_LITERAL*/const [1]]) => "hello";
''');
  }

  test_downwardsInferenceOnConstructorArguments_inferDownwards() async {
    await checkFileElement('''
class F0 {
  F0(List<int> a) {}
}
class F1 {
  F1({List<int> a}) {}
}
class F2 {
  F2(Iterable<int> a) {}
}
class F3 {
  F3(Iterable<Iterable<int>> a) {}
}
class F4 {
  F4({Iterable<Iterable<int>> a}) {}
}
void main() {
  new F0(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F0(/*info:INFERRED_TYPE_LITERAL*/[3]);
  new F0(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F0(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello",
                                      3]);

  new F1(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  new F1(a: /*info:INFERRED_TYPE_LITERAL*/[3]);
  new F1(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F1(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  new F2(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F2(/*info:INFERRED_TYPE_LITERAL*/[3]);
  new F2(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F2(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  new F3(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"],
                   /*info:INFERRED_TYPE_LITERAL*/[3]]);

  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"],
                      /*info:INFERRED_TYPE_LITERAL*/[3]]);
}
''');
  }

  test_downwardsInferenceOnFunctionArguments_inferDownwards() async {
    await checkFileElement('''
void f0(List<int> a) {}
void f1({List<int> a}) {}
void f2(Iterable<int> a) {}
void f3(Iterable<Iterable<int>> a) {}
void f4({Iterable<Iterable<int>> a}) {}
void main() {
  f0(/*info:INFERRED_TYPE_LITERAL*/[]);
  f0(/*info:INFERRED_TYPE_LITERAL*/[3]);
  f0(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  f0(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  f1(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  f1(a: /*info:INFERRED_TYPE_LITERAL*/[3]);
  f1(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  f1(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  f2(/*info:INFERRED_TYPE_LITERAL*/[]);
  f2(/*info:INFERRED_TYPE_LITERAL*/[3]);
  f2(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  f2(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  f3(/*info:INFERRED_TYPE_LITERAL*/[]);
  f3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  f3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  f3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"], /*info:INFERRED_TYPE_LITERAL*/[3]]);

  f4(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  f4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  f4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  f4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"], /*info:INFERRED_TYPE_LITERAL*/[3]]);
}
''');
  }

  test_downwardsInferenceOnFunctionExpressions() async {
    await checkFileElement('''
typedef T Function2<S, T>(S x);

void main () {
  {
    Function2<int, String> l0 = /*info:INFERRED_TYPE_CLOSURE*/(int x) => null;
    Function2<int, String> l1 = (int x) => "hello";
    Function2<int, String> l2 = /*error:INVALID_ASSIGNMENT*/(String x) => "hello";
    Function2<int, String> l3 = /*error:INVALID_ASSIGNMENT*/(int x) => 3;
    Function2<int, String> l4 = /*info:INFERRED_TYPE_CLOSURE*/(int x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
  }
  {
    Function2<int, String> l0 = /*info:INFERRED_TYPE_CLOSURE*/(x) => null;
    Function2<int, String> l1 = /*info:INFERRED_TYPE_CLOSURE*/(x) => "hello";
    Function2<int, String> l2 = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/(x) => 3;
    Function2<int, String> l3 = /*info:INFERRED_TYPE_CLOSURE*/(x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
    Function2<int, String> l4 = /*info:INFERRED_TYPE_CLOSURE*/(x) {return /*error:RETURN_OF_INVALID_TYPE*/x;};
  }
  {
    Function2<int, List<String>> l0 = /*info:INFERRED_TYPE_CLOSURE*/(int x) => null;
    Function2<int, List<String>> l1 = (int x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    Function2<int, List<String>> l2 = /*error:INVALID_ASSIGNMENT*/(String x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    Function2<int, List<String>> l3 = (int x) => /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];
    Function2<int, List<String>> l4 = /*info:INFERRED_TYPE_CLOSURE*/(int x) {return /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];};
  }
  {
    Function2<int, int> l0 = /*info:INFERRED_TYPE_CLOSURE*/(x) => x;
    Function2<int, int> l1 = /*info:INFERRED_TYPE_CLOSURE*/(x) => x+1;
    Function2<int, String> l2 = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/(x) => x;
    Function2<int, String> l3 = /*info:INFERRED_TYPE_CLOSURE*/(x) => /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/x./*error:UNDEFINED_METHOD*/substring(3);
    Function2<String, String> l4 = /*info:INFERRED_TYPE_CLOSURE*/(x) => x.substring(3);
  }
}
''');
  }

  test_downwardsInferenceOnFunctionOfTUsingTheT() async {
    await checkFileElement('''
void main () {
  {
    T f<T>(T x) => null;
    var v1 = f;
    v1 = /*info:INFERRED_TYPE_CLOSURE*/<S>(x) => x;
  }
  {
    List<T> f<T>(T x) => null;
    var v2 = f;
    v2 = /*info:INFERRED_TYPE_CLOSURE*/<S>(x) => /*info:INFERRED_TYPE_LITERAL*/[x];
    Iterable<int> r = v2(42);
    Iterable<String> s = v2('hello');
    Iterable<List<int>> t = v2(<int>[]);
    Iterable<num> u = v2(42);
    Iterable<num> v = v2<num>(42);
  }
}
''');
  }

  test_downwardsInferenceOnGenericConstructorArguments_emptyList() async {
    await checkFileElement('''
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}
void main() {
  new F3(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[]);
}
''');
  }

  test_downwardsInferenceOnGenericConstructorArguments_inferDownwards() async {
    await checkFileElement('''
class F0<T> {
  F0(List<T> a) {}
}
class F1<T> {
  F1({List<T> a}) {}
}
class F2<T> {
  F2(Iterable<T> a) {}
}
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}
void main() {
  new F0<int>(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F0<int>(/*info:INFERRED_TYPE_LITERAL*/[3]);
  new F0<int>(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F0<int>(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello",
                                      3]);

  new F1<int>(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  new F1<int>(a: /*info:INFERRED_TYPE_LITERAL*/[3]);
  new F1<int>(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F1<int>(a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  new F2<int>(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F2<int>(/*info:INFERRED_TYPE_LITERAL*/[3]);
  new F2<int>(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]);
  new F2<int>(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3]);

  new F3<int>(/*info:INFERRED_TYPE_LITERAL*/[]);
  new F3<int>(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F3<int>(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  new F3<int>(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"],
                   /*info:INFERRED_TYPE_LITERAL*/[3]]);

  new F4<int>(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  new F4<int>(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F4<int>(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"]]);
  new F4<int>(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"],
                      /*info:INFERRED_TYPE_LITERAL*/[3]]);

  new F3(/*info:INFERRED_TYPE_LITERAL*/[]);
  var f31 = /*info:INFERRED_TYPE_ALLOCATION*/new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  var f32 = /*info:INFERRED_TYPE_ALLOCATION*/new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"]]);
  var f33 = /*info:INFERRED_TYPE_ALLOCATION*/new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"],
                                        /*info:INFERRED_TYPE_LITERAL*/[3]]);

  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  /*info:INFERRED_TYPE_ALLOCATION*/new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  /*info:INFERRED_TYPE_ALLOCATION*/new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"]]);
  /*info:INFERRED_TYPE_ALLOCATION*/new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"],
                                           /*info:INFERRED_TYPE_LITERAL*/[3]]);
}
''');
  }

  test_downwardsInferenceOnGenericFunctionExpressions() async {
    await checkFileElement('''
void main () {
  {
    String f<S>(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE*/<T>(int x) => null;
    v = <T>(int x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/<T>(String x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/<T>(int x) => 3;
    v = /*info:INFERRED_TYPE_CLOSURE*/<T>(int x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
  }
  {
    String f<S>(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*/<T>(x) => null;
    v = /*info:INFERRED_TYPE_CLOSURE*/<T>(x) => "hello";
    v = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/<T>(x) => 3;
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*/<T>(x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*/<T>(x) {return /*error:RETURN_OF_INVALID_TYPE*/x;};
  }
  {
    List<String> f<S>(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE*/<T>(int x) => null;
    v = <T>(int x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    v = /*error:INVALID_ASSIGNMENT*/<T>(String x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    v = <T>(int x) => /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];
    v = /*info:INFERRED_TYPE_CLOSURE*/<T>(int x) {return /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];};
  }
  {
    int int2int<S>(int x) => null;
    String int2String<T>(int x) => null;
    String string2String<T>(String x) => null;
    var x = int2int;
    x = /*info:INFERRED_TYPE_CLOSURE*/<T>(x) => x;
    x = /*info:INFERRED_TYPE_CLOSURE*/<T>(x) => x+1;
    var y = int2String;
    y = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/<T>(x) => x;
    y = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*/<T>(x) => /*info:DYNAMIC_INVOKE, info:DYNAMIC_CAST*/x./*error:UNDEFINED_METHOD*/substring(3);
    var z = string2String;
    z = /*info:INFERRED_TYPE_CLOSURE*/<T>(x) => x.substring(3);
  }
}
''');
  }

  test_downwardsInferenceOnInstanceCreations_inferDownwards() async {
    await checkFileElement('''
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
}

class F<S, T> extends A<S, T> {
  F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
  F.named(S x, T y, [S a, T b]) : super(a, b);
}

void main() {
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new A(3, "hello");
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new A.named(3, "hello");
    A<int, String> a2 = new A<int, String>(3, "hello");
    A<int, String> a3 = new A<int, String>.named(3, "hello");
    A<int, String> a4 = /*error:INVALID_CAST_NEW_EXPR*/new A<int, dynamic>(3, "hello");
    A<int, String> a5 = /*error:INVALID_CAST_NEW_EXPR*/new A<dynamic, dynamic>.named(3, "hello");
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new A(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello",
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new A.named(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello",
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new B("hello", 3);
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new B.named("hello", 3);
    A<int, String> a2 = new B<String, int>("hello", 3);
    A<int, String> a3 = new B<String, int>.named("hello", 3);
    A<int, String> a4 = /*error:INVALID_ASSIGNMENT*/new B<String, dynamic>("hello", 3);
    A<int, String> a5 = /*error:INVALID_ASSIGNMENT*/new B<dynamic, dynamic>.named("hello", 3);
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new B(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new B.named(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");
  }
  {
    A<int, int> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new C(3);
    A<int, int> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new C.named(3);
    A<int, int> a2 = new C<int>(3);
    A<int, int> a3 = new C<int>.named(3);
    A<int, int> a4 = /*error:INVALID_ASSIGNMENT*/new C<dynamic>(3);
    A<int, int> a5 = /*error:INVALID_ASSIGNMENT*/new C<dynamic>.named(3);
  }
  {
    A<int, int> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new C(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");
    A<int, int> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new C.named(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new D("hello");
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new D.named("hello");
    A<int, String> a2 = new D<int, String>("hello");
    A<int, String> a3 = new D<String, String>.named("hello");
    A<int, String> a4 = /*error:INVALID_ASSIGNMENT*/new D<num, dynamic>("hello");
    A<int, String> a5 = /*error:INVALID_ASSIGNMENT*/new D<dynamic, dynamic>.named("hello");
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new D(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new D.named(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
  }
  {
    A<C<int>, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new E("hello");
  }
  { // Check named and optional arguments
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new F(3, "hello",
        a: /*info:INFERRED_TYPE_LITERAL*/[3],
        b: /*info:INFERRED_TYPE_LITERAL*/["hello"]);
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new F(3, "hello",
        a: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"],
        b: /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3]);
    A<int, String> a2 = /*info:INFERRED_TYPE_ALLOCATION*/new F.named(3, "hello", 3, "hello");
    A<int, String> a3 = /*info:INFERRED_TYPE_ALLOCATION*/new F.named(3, "hello");
    A<int, String> a4 = /*info:INFERRED_TYPE_ALLOCATION*/new F.named(3, "hello",
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello", /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
    A<int, String> a5 = /*info:INFERRED_TYPE_ALLOCATION*/new F.named(3, "hello",
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");
  }
}
''');
  }

  test_downwardsInferenceOnListLiterals_inferDownwards() async {
    await checkFileElement('''
void foo([List<String> list1 = /*info:INFERRED_TYPE_LITERAL*/const [],
          List<String> list2 = /*info:INFERRED_TYPE_LITERAL*/const [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/42]]) {
}

void main() {
  {
    List<int> l0 = /*info:INFERRED_TYPE_LITERAL*/[];
    List<int> l1 = /*info:INFERRED_TYPE_LITERAL*/[3];
    List<int> l2 = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
    List<int> l3 = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3];
  }
  {
    List<dynamic> l0 = [];
    List<dynamic> l1 = [3];
    List<dynamic> l2 = ["hello"];
    List<dynamic> l3 = ["hello", 3];
  }
  {
    List<int> l0 = /*error:INVALID_CAST_LITERAL_LIST*/<num>[];
    List<int> l1 = /*error:INVALID_CAST_LITERAL_LIST*/<num>[3];
    List<int> l2 = /*error:INVALID_CAST_LITERAL_LIST*/<num>[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
    List<int> l3 = /*error:INVALID_CAST_LITERAL_LIST*/<num>[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3];
  }
  {
    Iterable<int> i0 = /*info:INFERRED_TYPE_LITERAL*/[];
    Iterable<int> i1 = /*info:INFERRED_TYPE_LITERAL*/[3];
    Iterable<int> i2 = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
    Iterable<int> i3 = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3];
  }
  {
    const List<int> c0 = /*info:INFERRED_TYPE_LITERAL*/const [];
    const List<int> c1 = /*info:INFERRED_TYPE_LITERAL*/const [3];
    const List<int> c2 = /*info:INFERRED_TYPE_LITERAL*/const [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
    const List<int> c3 = /*info:INFERRED_TYPE_LITERAL*/const [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3];
  }
}
''');
  }

  test_downwardsInferenceOnListLiterals_inferIfValueTypesMatchContext() async {
    await checkFileElement(r'''
class DartType {}
typedef void Asserter<T>(T type);
typedef Asserter<T> AsserterBuilder<S, T>(S arg);

Asserter<DartType> _isInt;
Asserter<DartType> _isString;

abstract class C {
  static AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
  static AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    assertBOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    assertCOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    assertDOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    assertEOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  }
  }

  abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    this.assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    this.assertDOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
    assertEOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

main() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  assertBOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  assertCOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  C.assertBOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  C.assertCOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);

  C c;
  c.assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  c.assertDOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);

  G<int> g;
  g.assertAOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
  g.assertDOf(/*info:INFERRED_TYPE_LITERAL*/[_isInt, _isString]);
}
''');
  }

  test_downwardsInferenceOnMapLiterals() async {
    await checkFileElement('''
void foo([Map<int, String> m1 = /*info:INFERRED_TYPE_LITERAL*/const {1: "hello"},
    Map<int, String> m2 = /*info:INFERRED_TYPE_LITERAL*/const {
      // One error is from type checking and the other is from const evaluation.
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello":
          "world"
    }]) {
}
void main() {
  {
    Map<int, String> l0 = /*info:INFERRED_TYPE_LITERAL*/{};
    Map<int, String> l1 = /*info:INFERRED_TYPE_LITERAL*/{3: "hello"};
    Map<int, String> l2 = /*info:INFERRED_TYPE_LITERAL*/{
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello": "hello"
    };
    Map<int, String> l3 = /*info:INFERRED_TYPE_LITERAL*/{
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
    Map<int, String> l4 = /*info:INFERRED_TYPE_LITERAL*/{
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
  }
  {
    Map<dynamic, dynamic> l0 = {};
    Map<dynamic, dynamic> l1 = {3: "hello"};
    Map<dynamic, dynamic> l2 = {"hello": "hello"};
    Map<dynamic, dynamic> l3 = {3: 3};
    Map<dynamic, dynamic> l4 = {3:"hello", "hello": 3};
  }
  {
    Map<dynamic, String> l0 = /*info:INFERRED_TYPE_LITERAL*/{};
    Map<dynamic, String> l1 = /*info:INFERRED_TYPE_LITERAL*/{3: "hello"};
    Map<dynamic, String> l2 = /*info:INFERRED_TYPE_LITERAL*/{"hello": "hello"};
    Map<dynamic, String> l3 = /*info:INFERRED_TYPE_LITERAL*/{
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
    Map<dynamic, String> l4 = /*info:INFERRED_TYPE_LITERAL*/{
      3: "hello",
      "hello": /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
  }
  {
    Map<int, dynamic> l0 = /*info:INFERRED_TYPE_LITERAL*/{};
    Map<int, dynamic> l1 = /*info:INFERRED_TYPE_LITERAL*/{3: "hello"};
    Map<int, dynamic> l2 = /*info:INFERRED_TYPE_LITERAL*/{
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello": "hello"
    };
    Map<int, dynamic> l3 = /*info:INFERRED_TYPE_LITERAL*/{3: 3};
    Map<int, dynamic> l4 = /*info:INFERRED_TYPE_LITERAL*/{
      3:"hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello": 3
    };
  }
  {
    Map<int, String> l0 = /*error:INVALID_CAST_LITERAL_MAP*/<num, dynamic>{};
    Map<int, String> l1 = /*error:INVALID_CAST_LITERAL_MAP*/<num, dynamic>{3: "hello"};
    Map<int, String> l3 = /*error:INVALID_CAST_LITERAL_MAP*/<num, dynamic>{3: 3};
  }
  {
    const Map<int, String> l0 = /*info:INFERRED_TYPE_LITERAL*/const {};
    const Map<int, String> l1 = /*info:INFERRED_TYPE_LITERAL*/const {3: "hello"};
    const Map<int, String> l2 = /*info:INFERRED_TYPE_LITERAL*/const {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello":
          "hello"
    };
    const Map<int, String> l3 = /*info:INFERRED_TYPE_LITERAL*/const {
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
    const Map<int, String> l4 = /*info:INFERRED_TYPE_LITERAL*/const {
      3:"hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/"hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/3
    };
  }
}
''');
  }

  test_downwardsInferenceYieldYieldStar() async {
    await checkFileElement('''
import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

Stream<List<int>> foo() async* {
  yield /*info:INFERRED_TYPE_LITERAL*/[];
  yield /*error:YIELD_OF_INVALID_TYPE*/new MyStream();
  yield* /*error:YIELD_OF_INVALID_TYPE*/[];
  yield* /*info:INFERRED_TYPE_ALLOCATION*/new MyStream();
}

Iterable<Map<int, int>> bar() sync* {
  yield /*info:INFERRED_TYPE_LITERAL*/{};
  yield /*error:YIELD_OF_INVALID_TYPE*/new List();
  yield* /*error:YIELD_OF_INVALID_TYPE*/{};
  yield* /*info:INFERRED_TYPE_ALLOCATION*/new List();
}
''');
  }

  test_fieldRefersToStaticGetter() async {
    var mainUnit = await checkFileElement('''
class C {
  final x = _x;
  static int get _x => null;
}
''');
    var x = mainUnit.types[0].fields[0];
    expect(x.type.toString(), 'int');
  }

  test_fieldRefersToTopLevelGetter() async {
    var mainUnit = await checkFileElement('''
class C {
  final x = y;
}
int get y => null;
''');
    var x = mainUnit.types[0].fields[0];
    expect(x.type.toString(), 'int');
  }

  test_futureOr_subtyping() async {
    await checkFileElement(r'''
import 'dart:async';
void add(int x) {}
add2(int y) {}
main() {
  Future<int> f;
  var a = f.then(add);
  var b = f.then(add2);
}
  ''');
  }

  test_futureThen() async {
    String build({String declared, String downwards, String upwards}) => '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  $declared f;
  $downwards<int> t1 = f.then((_) async => await new $upwards<int>.value(3));
  $downwards<int> t2 = f.then(/*info:INFERRED_TYPE_CLOSURE*/(_) async {
     return await new $upwards<int>.value(3);});
  $downwards<int> t3 = f.then((_) async => 3);
  $downwards<int> t4 = f.then(/*info:INFERRED_TYPE_CLOSURE*/(_) async {
    return 3;});
  $downwards<int> t5 = f.then((_) => new $upwards<int>.value(3));
  $downwards<int> t6 = f.then(/*info:INFERRED_TYPE_CLOSURE*/(_) {return new $upwards<int>.value(3);});
  $downwards<int> t7 = f.then((_) async => new $upwards<int>.value(3));
  $downwards<int> t8 = f.then(/*info:INFERRED_TYPE_CLOSURE*/(_) async {
    return new $upwards<int>.value(3);});
}
''';

    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "Future"));
    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "MyFuture", downwards: "MyFuture", upwards: "Future"));
    await checkFileElement(build(
        declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "Future"));
  }

  test_futureThen_conditional() async {
    String build({String declared, String downwards, String upwards}) => '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  $declared<bool> f;
  $downwards<int> t1 = f.then(/*info:INFERRED_TYPE_CLOSURE*/
      (x) async => x ? 2 : await new $upwards<int>.value(3));
  $downwards<int> t2 = f.then(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(x) async { // TODO(leafp): Why the duplicate here?
    return /*info:DOWN_CAST_COMPOSITE*/await x ? 2 : new $upwards<int>.value(3);});
  $downwards<int> t5 = f.then(/*info:INFERRED_TYPE_CLOSURE,error:INVALID_CAST_FUNCTION_EXPR*/
      (x) => x ? 2 : new $upwards<int>.value(3));
  $downwards<int> t6 = f.then(/*info:INFERRED_TYPE_CLOSURE*/
      (x) {return /*info:DOWN_CAST_COMPOSITE*/x ? 2 : new $upwards<int>.value(3);});
}
''';
    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "Future"));
    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "MyFuture", downwards: "MyFuture", upwards: "Future"));
    await checkFileElement(build(
        declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "Future"));
  }

  test_futureThen_downwardsMethodTarget() async {
    // Not working yet, see: https://github.com/dart-lang/sdk/issues/27114
    await checkFileElement(r'''
import 'dart:async';
main() {
  Future<int> f;
  Future<List<int>> b = /*info:ASSIGNMENT_CAST should be pass*/f
      .then(/*info:INFERRED_TYPE_CLOSURE*/(x) => [])
      .whenComplete(/*info:INFERRED_TYPE_CLOSURE*/() {});
  b = f.then(/*info:INFERRED_TYPE_CLOSURE*/(x) => /*info:INFERRED_TYPE_LITERAL*/[]);
}
  ''');
  }

  test_futureThen_explicitFuture() async {
    await checkFileElement(r'''
import "dart:async";
m1() {
  Future<int> f;
  var x = f.then<Future<List<int>>>(/*info:INFERRED_TYPE_CLOSURE,
                                      error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/
                                    (x) => []);
  Future<List<int>> y = x;
}
m2() {
  Future<int> f;
  var x = f.then<List<int>>(/*info:INFERRED_TYPE_CLOSURE*/(x) => /*info:INFERRED_TYPE_LITERAL*/[]);
  Future<List<int>> y = x;
}
  ''');
  }

  test_futureThen_upwards() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27088.
    String build({String declared, String downwards, String upwards}) => '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  var f = foo().then((_) => 2.3);
  $downwards<int> f2 = /*error:INVALID_ASSIGNMENT*/f;

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  $downwards<num> f3 = /*info:UNNECESSARY_CAST*/foo().then(
      (_) => 2.3) as $upwards<double>;
}
$declared foo() => new $declared<int>.value(1);
    ''';
    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "Future"));
    await checkFileElement(build(
        declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "Future"));
  }

  test_futureThen_upwardsFromBlock() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27113.
    await checkFileElement(r'''
import 'dart:async';
main() {
  Future<int> base;
  var f = base.then(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(x) { return x == 0; });
  var g = base.then(/*info:INFERRED_TYPE_CLOSURE*/(x) => x == 0);
  Future<bool> b = f;
  b = g;
}
  ''');
  }

  test_futureUnion_asyncConditional() async {
    String build(
            {String declared,
            String downwards,
            String upwards,
            String expectedInfo: ''}) =>
        '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

$downwards<int> g1(bool x) async {
  return /*info:DOWN_CAST_COMPOSITE*/x ? 42 : /*info:INFERRED_TYPE_ALLOCATION*/new $upwards.value(42); }
$downwards<int> g2(bool x) async =>
  /*info:DOWN_CAST_COMPOSITE*/x ? 42 : /*info:INFERRED_TYPE_ALLOCATION*/new $upwards.value(42);
$downwards<int> g3(bool x) async {
  var y = x ? 42 : ${expectedInfo}new $upwards.value(42);
  return /*info:DOWN_CAST_COMPOSITE*/y;
}
    ''';
    await checkFileElement(build(
        downwards: "Future",
        upwards: "Future",
        expectedInfo: '/*info:INFERRED_TYPE_ALLOCATION*/'));
    await checkFileElement(build(downwards: "Future", upwards: "MyFuture"));
  }

  test_futureUnion_downwards() async {
    String build(
        {String declared,
        String downwards,
        String upwards,
        String expectedError: ''}) {
      return '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([x]) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

$declared f;
// Instantiates Future<int>
$downwards<int> t1 = f.then((_) =>
   /*info:INFERRED_TYPE_ALLOCATION*/new $upwards.value($expectedError'hi'));

// Instantiates List<int>
$downwards<List<int>> t2 = f.then((_) => /*info:INFERRED_TYPE_LITERAL*/[3]);
$downwards<List<int>> g2() async { return /*info:INFERRED_TYPE_LITERAL*/[3]; }
$downwards<List<int>> g3() async {
  return /*info:INFERRED_TYPE_ALLOCATION*/new $upwards.value(
      /*info:INFERRED_TYPE_LITERAL*/[3]); }
''';
    }

    await checkFileElement(build(
        declared: "MyFuture",
        downwards: "Future",
        upwards: "Future",
        expectedError: '/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'));
    await checkFileElement(
        build(declared: "MyFuture", downwards: "Future", upwards: "MyFuture"));
    await checkFileElement(build(
        declared: "Future",
        downwards: "Future",
        upwards: "Future",
        expectedError: '/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'));
    await checkFileElement(
        build(declared: "Future", downwards: "Future", upwards: "MyFuture"));
  }

  test_futureUnion_downwardsGenericMethodWithFutureReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27134
    //
    // We need to take a future union into account for both directions of
    // generic method inference.
    await checkFileElement(r'''
import 'dart:async';

foo() async {
  Future<List<A>> f1 = null;
  Future<List<A>> f2 = null;
  List<List<A>> merged = await Future.wait(/*info:INFERRED_TYPE_LITERAL*/[f1, f2]);
}

class A {}
  ''');
  }

  test_futureUnion_downwardsGenericMethodWithGenericReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27284
    await checkFileElement(r'''
import 'dart:async';

T id<T>(T x) => x;

main() async {
  Future<String> f;
  String s = await id(f);
}
  ''');
  }

  test_futureUnion_upwardsGenericMethods() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27151
    await checkFileElement(r'''
import 'dart:async';

main() async {
  var b = new Future<B>.value(new B());
  var c = new Future<C>.value(new C());
  var lll = /*info:INFERRED_TYPE_LITERAL*/[b, c];
  var result = await Future.wait(lll);
  var result2 = await Future.wait(/*info:INFERRED_TYPE_LITERAL*/[b, c]);
  List<A> list = result;
  list = result2;
}

class A {}
class B extends A {}
class C extends A {}
  ''');
  }

  test_genericFunctions_returnTypedef() async {
    await checkFileElement(r'''
typedef void ToValue<T>(T value);

main() {
  ToValue<T> f<T>(T x) => null;
  var x = f<int>(42);
  var y = f(42);
  ToValue<int> takesInt = x;
  takesInt = y;
}
  ''');
  }

  test_genericMethods_basicDownwardInference() async {
    await checkFileElement(r'''
T f<S, T>(S s) => null;
main() {
  String x = f(42);
  String y = (f)(42);
}
''');
  }

  test_genericMethods_correctlyRecognizeGenericUpperBound() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.
    await checkFileElement(r'''
class Foo<T extends Pattern> {
  U method<U extends T>(U u) => u;
}
main() {
/*!!!
  String s;
  var a = new Foo().method<String>("str");
  s = a;
  new Foo();

  var b = new Foo<String>().method("str");
  s = b;
  var c = new Foo().method("str");
  s = c;
  */

  new Foo<String>()./*error:COULD_NOT_INFER*/method(42);
}
''');
  }

  test_genericMethods_dartMathMinMax() async {
    await checkFileElement('''
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
  printInt(/*info:DOWN_CAST_IMPLICIT*/myMax(1, 2));
  printInt(myMax(1, 2) as int);

  // Mixing int and double means return type is num.
  printInt(max(1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/2.0));
  printInt(min(1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/2.0));
  printDouble(max(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/1, 2.0));
  printDouble(min(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/1, 2.0));

  // Types other than int and double are not accepted.
  printInt(
      min(
          /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hi",
          /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"there"));
}
''');
  }

  test_genericMethods_doNotInferInvalidOverrideOfGenericMethod() async {
    await checkFileElement('''
class C {
T m<T>(T x) => x;
}
class D extends C {
/*error:INVALID_METHOD_OVERRIDE*/m(x) => x;
}
main() {
  int y = /*info:DYNAMIC_CAST*/new D()./*error:WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD*/m<int>(42);
  print(y);
}
''');
  }

  test_genericMethods_downwardsInferenceAffectsArguments() async {
    await checkFileElement(r'''
T f<T>(List<T> s) => null;
main() {
  String x = f(/*info:INFERRED_TYPE_LITERAL*/['hi']);
  String y = f(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/42]);
}
''');
  }

  test_genericMethods_downwardsInferenceFold() async {
    // Regression from https://github.com/dart-lang/sdk/issues/25491
    // The first example works now, but the latter requires a full solution to
    // https://github.com/dart-lang/sdk/issues/25490
    await checkFileElement(r'''
void main() {
  List<int> o;
  int y = o.fold(0, /*info:INFERRED_TYPE_CLOSURE*/(x, y) => x + y);
  var z = o.fold(0, /*info:INFERRED_TYPE_CLOSURE*/(x, y) => /*info:DYNAMIC_INVOKE*/x + y);
  y = /*info:DYNAMIC_CAST*/z;
}
void functionExpressionInvocation() {
  List<int> o;
  int y = (o.fold)(0, /*info:INFERRED_TYPE_CLOSURE*/(x, y) => x + y);
  var z = (o.fold)(0, /*info:INFERRED_TYPE_CLOSURE*/(x, y) => /*info:DYNAMIC_INVOKE*/x + y);
  y = /*info:DYNAMIC_CAST*/z;
}
''');
  }

  test_genericMethods_handleOverrideOfNonGenericWithGeneric() async {
    // Regression test for crash when adding genericity
    await checkFileElement('''
class C {
  m(x) => x;
  dynamic g(int x) => x;
}
class D extends C {
  /*error:INVALID_METHOD_OVERRIDE*/T m<T>(T x) => x;
  /*error:INVALID_METHOD_OVERRIDE*/T g<T>(T x) => x;
}
main() {
  int y = /*info:DYNAMIC_CAST*/(/*info:UNNECESSARY_CAST*/new D() as C).m(42);
  print(y);
}
''');
  }

  test_genericMethods_inferenceError() async {
    await checkFileElement(r'''
main() {
  List<String> y;
  Iterable<String> x = y.map(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/(String z) => 1.0);
}
  ''');
  }

  test_genericMethods_inferGenericFunctionParameterType() async {
    var mainUnit = await checkFileElement('''
class C<T> extends D<T> {
  f<U>(x) {}
}
class D<T> {
  F<U> f<U>(U u) => null;
}
typedef void F<V>(V v);
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(U) → (U) → void');
  }

  test_genericMethods_inferGenericFunctionParameterType2() async {
    var mainUnit = await checkFileElement('''
class C<T> extends D<T> {
  f<U>(g) => null;
}
abstract class D<T> {
  void f<U>(G<U> g);
}
typedef List<V> G<V>();
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(() → List<U>) → void');
  }

  test_genericMethods_inferGenericFunctionReturnType() async {
    var mainUnit = await checkFileElement('''
class C<T> extends D<T> {
  f<U>(x) {}
}
class D<T> {
  F<U> f<U>(U u) => null;
}
typedef V F<V>();
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(U) → () → U');
  }

  test_genericMethods_inferGenericInstantiation() async {
    await checkFileElement('''
import 'dart:math' as math;
import 'dart:math' show min;

class C {
T m<T extends num>(T x, T y) => null;
}

main() {
takeIII(math.max);
takeDDD(math.max);
takeNNN(math.max);
takeIDN(math.max);
takeDIN(math.max);
takeIIN(math.max);
takeDDN(math.max);
takeIIO(math.max);
takeDDO(math.max);

takeOOI(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/math.max);
takeIDI(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeDID(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeOON(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/math.max);
takeOOO(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/math.max);

// Also test SimpleIdentifier
takeIII(min);
takeDDD(min);
takeNNN(min);
takeIDN(min);
takeDIN(min);
takeIIN(min);
takeDDN(min);
takeIIO(min);
takeDDO(min);

takeOOI(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/min);
takeIDI(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeDID(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeOON(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/min);
takeOOO(/*error:COULD_NOT_INFER,error:INVALID_CAST_FUNCTION*/min);

// Also PropertyAccess
takeIII(new C().m);
takeDDD(new C().m);
takeNNN(new C().m);
takeIDN(new C().m);
takeDIN(new C().m);
takeIIN(new C().m);
takeDDN(new C().m);
takeIIO(new C().m);
takeDDO(new C().m);

// Note: this is a warning because a downcast of a method tear-off could work
// (derived method can be a subtype):
//
//     class D extends C {
//       S m<S extends num>(Object x, Object y);
//     }
//
// That's legal because we're loosening parameter types.
//
// We do issue the inference error though, similar to generic function calls.
takeOON(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/new C().m);
takeOOO(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/new C().m);

// Note: this is a warning because a downcast of a method tear-off could work
// in "normal" Dart, due to bivariance.
//
// We do issue the inference error though, similar to generic function calls.
takeOOI(/*error:COULD_NOT_INFER,info:DOWN_CAST_COMPOSITE*/new C().m);

takeIDI(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
takeDID(/*error:COULD_NOT_INFER,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
}

void takeIII(int fn(int a, int b)) {}
void takeDDD(double fn(double a, double b)) {}
void takeIDI(int fn(double a, int b)) {}
void takeDID(double fn(int a, double b)) {}
void takeIDN(num fn(double a, int b)) {}
void takeDIN(num fn(int a, double b)) {}
void takeIIN(num fn(int a, int b)) {}
void takeDDN(num fn(double a, double b)) {}
void takeNNN(num fn(num a, num b)) {}
void takeOON(num fn(Object a, Object b)) {}
void takeOOO(num fn(Object a, Object b)) {}
void takeOOI(int fn(Object a, Object b)) {}
void takeIIO(Object fn(int a, int b)) {}
void takeDDO(Object fn(double a, double b)) {}
''');
  }

  test_genericMethods_inferGenericMethodType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25668
    await checkFileElement('''
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

  test_genericMethods_inferJSBuiltin() async {
    // TODO(jmesserly): we should change how this inference works.
    // For now this test will cover what we use.
    await checkFileElement('''
/*error:IMPORT_INTERNAL_LIBRARY*/import 'dart:_foreign_helper' show JS;
main() {
  String x = /*error:INVALID_ASSIGNMENT*/JS('int', '42');
  var y = JS('String', '"hello"');
  y = "world";
  y = /*error:INVALID_ASSIGNMENT*/42;
}
''');
  }

  test_genericMethods_IterableAndFuture() async {
    await checkFileElement('''
import 'dart:async';

Future<int> make(int x) => (/*info:INFERRED_TYPE_ALLOCATION*/new Future(() => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(list);
  Future<String> results2 = results.then((List<int> list)
    => list.fold('', /*info:INFERRED_TYPE_CLOSURE*/(x, y) => /*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/x /*error:UNDEFINED_OPERATOR*/+ y.toString()));

  Future<String> results3 = results.then((List<int> list)
    => list.fold('', /*info:INFERRED_TYPE_CLOSURE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/(String x, y) => x + y.toString()));

  Future<String> results4 = results.then((List<int> list)
    => list.fold<String>('', /*info:INFERRED_TYPE_CLOSURE*/(x, y) => x + y.toString()));
}
''');
  }

  test_genericMethods_nestedGenericInstantiation() async {
    await checkFileElement(r'''
import 'dart:math' as math;
class Trace {
  List<Frame> frames = /*info:INFERRED_TYPE_LITERAL*/[];
}
class Frame {
  String location = '';
}
main() {
  List<Trace> traces = /*info:INFERRED_TYPE_LITERAL*/[];
  var longest = traces.map(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(trace) {
    return trace.frames.map(/*info:INFERRED_TYPE_CLOSURE*/(frame) => frame.location.length)
        .fold(0, math.max);
  }).fold(0, math.max);
}
  ''');
  }

  test_genericMethods_usesGreatestLowerBound() async {
    var unit = await checkFile(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;

main() {
  var v = generic((F f) => null, (G g) => null);
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), '(num) → List<int>');
  }

  test_genericMethods_usesGreatestLowerBound_topLevel() async {
    var mainUnit = await checkFileElement(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;

var v = generic((F f) => null, (G g) => null);
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(num) → List<int>');
  }

  test_infer_assignToIndex() async {
    await checkFileElement(r'''
List<double> a = <double>[];
var b = (a[0] = 1.0);
''');
  }

  test_infer_assignToProperty() async {
    await checkFileElement(r'''
class A {
  int f;
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
    await checkFileElement(r'''
class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}
class B {
  A a;
}
var v_prefix_pp = (++new B().a);
var v_prefix_mm = (--new B().a);
var v_postfix_pp = (new B().a++);
var v_postfix_mm = (new B().a--);
''');
  }

  test_infer_assignToRef() async {
    await checkFileElement(r'''
class A {
  int f;
}
A a = new A();
var b = (a.f = 1);
var c = 0;
var d = (c = 1);
''');
  }

  test_infer_binary_custom() async {
    await checkFileElement(r'''
class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}
var v_add = new A() + 'foo';
var v_minus = new A() - 'bar';
''');
  }

  test_infer_binary_doubleDouble() async {
    await checkFileElement(r'''
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
    await checkFileElement(r'''
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
    await checkFileElement(r'''
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
    await checkFileElement(r'''
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
    await checkFileElement(r'''
var a = 1 == 2 ? 1 : 2.0;
var b = 1 == 2 ? 1.0 : 2;
''');
  }

  test_infer_prefixExpression() async {
    await checkFileElement(r'''
var a_not = !true;
var a_complement = ~1;
var a_negate = -1;
''');
  }

  test_infer_prefixExpression_custom() async {
    await checkFileElement(r'''
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
    await checkFileElement(r'''
var t = true;
var a = (throw 0);
var b = (throw 0) ? 1 : 2;
var c = t ? (throw 1) : 2;
var d = t ? 1 : (throw 2);
''');
  }

  test_infer_typeCast() async {
    await checkFileElement(r'''
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
    await checkFileElement(r'''
var a = <int>[];
var b = <double>[1.0, 2.0, 3.0];
var c = <List<int>>[];
var d = <dynamic>[1, 2.0, false];
''');
  }

  test_infer_typedMapLiteral() async {
    await checkFileElement(r'''
var a = <int, String>{0: 'aaa', 1: 'bbb'};
var b = <double, int>{1.1: 1, 2.2: 2};
var c = <List<int>, Map<String, double>>{};
var d = <int, dynamic>{};
var e = <dynamic, int>{};
var f = <dynamic, dynamic>{};
''');
  }

  test_infer_use_of_void() async {
    await checkFileElement('''
class B {
  void f() {}
}
class C extends B {
  f() {}
}
var x = new C()./*info:USE_OF_VOID_RESULT*/f();
''');
  }

  test_inferConstsTransitively() async {
    addFile('''
const b1 = 2;
''', name: '/b.dart');
    addFile('''
import 'main.dart';
import 'b.dart';
const a1 = m2;
const a2 = b1;
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
const m1 = a1;
const m2 = a2;

foo() {
  int i;
  i = m1;
}
''');
  }

  test_inferCorrectlyOnMultipleVariablesDeclaredTogether() async {
    await checkFileElement('''
class A {
  var x, y = 2, z = "hi";
}

class B implements A {
  var x = 2, y = 3, z, w = 2;
}

foo() {
  String s;
  int i;

  s = /*info:DYNAMIC_CAST*/new B().x;
  s = /*error:INVALID_ASSIGNMENT*/new B().y;
  s = new B().z;
  s = /*error:INVALID_ASSIGNMENT*/new B().w;

  i = /*info:DYNAMIC_CAST*/new B().x;
  i = new B().y;
  i = /*error:INVALID_ASSIGNMENT*/new B().z;
  i = new B().w;
}
''');
  }

  test_inferedType_usesSyntheticFunctionType() async {
    var mainUnit = await checkFileElement('''
int f() => null;
String g() => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<() → Object>');
  }

  test_inferedType_usesSyntheticFunctionType_functionTypedParam() async {
    var mainUnit = await checkFileElement('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<((String) → int) → Object>');
  }

  test_inferedType_usesSyntheticFunctionType_namedParam() async {
    var mainUnit = await checkFileElement('''
int f({int x}) => null;
String g({int x}) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<({x: int}) → Object>');
  }

  test_inferedType_usesSyntheticFunctionType_positionalParam() async {
    var mainUnit = await checkFileElement('''
int f([int x]) => null;
String g([int x]) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<([int]) → Object>');
  }

  test_inferedType_usesSyntheticFunctionType_requiredParam() async {
    var mainUnit = await checkFileElement('''
int f(int x) => null;
String g(int x) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<(int) → Object>');
  }

  test_inferFromComplexExpressionsIfOuterMostValueIsPrecise() async {
    await checkFileElement('''
class A { int x; B operator+(other) => null; }
class B extends A { B(ignore); }
var a = new A();
// Note: it doesn't matter that some of these refer to 'x'.
var b = new B(/*error:UNDEFINED_IDENTIFIER*/x);  // allocations
var c1 = [/*error:UNDEFINED_IDENTIFIER*/x];      // list literals
var c2 = const [];
var d = <dynamic, dynamic>{'a': 'b'};     // map literals
var e = new A()..x = 3; // cascades
var f = 2 + 3;          // binary expressions are OK if the left operand
                        // is from a library in a different strongest
                        // connected component.
var g = -3;
var h = new A() + 3;
var i = /*error:UNDEFINED_OPERATOR,info:DYNAMIC_INVOKE*/- new A();
var j = /*info:UNNECESSARY_CAST*/null as B;

test1() {
  a = /*error:INVALID_ASSIGNMENT*/"hi";
  a = new B(3);
  b = /*error:INVALID_ASSIGNMENT*/"hi";
  b = new B(3);
  c1 = [];
  c1 = /*error:INVALID_ASSIGNMENT*/{};
  c2 = [];
  c2 = /*error:INVALID_ASSIGNMENT*/{};
  d = {};
  d = /*error:INVALID_ASSIGNMENT*/3;
  e = new A();
  e = /*error:INVALID_ASSIGNMENT*/{};
  f = 3;
  f = /*error:INVALID_ASSIGNMENT*/false;
  g = 1;
  g = /*error:INVALID_ASSIGNMENT*/false;
  h = /*error:INVALID_ASSIGNMENT*/false;
  h = new B('b');
  i = false;
  j = new B('b');
  j = /*error:INVALID_ASSIGNMENT*/false;
  j = /*error:INVALID_ASSIGNMENT*/[];
}
''');
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields() async {
    await checkFileElement('''
class A {
  var x;
}

class B implements A {
  var x = 2;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/new B().x;
  int z = /*info:DYNAMIC_CAST*/new B().x;
}
''');
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() async {
    await checkFileElement('''
class A {
  final x = null;
}

class B implements A {
  final x = 2;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/new B().x;
  int z = /*info:DYNAMIC_CAST*/new B().x;
}
''');
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn() async {
    addFile('''
import 'main.dart';
var x = 2; // ok to infer
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
var y = x; // now ok :)

test1() {
  int t = 3;
  t = x;
  t = y;
}
''');
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn2() async {
    addFile('''
import 'main.dart';
class A { static var x = 2; }
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  int t = 3;
  t = A.x;
  t = B.y;
}
''');
  }

  test_inferFromVariablesInNonCycleImportsWithFlag() async {
    addFile('''
var x = 2;
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
var y = x;

test1() {
  x = /*error:INVALID_ASSIGNMENT*/"hi";
  y = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_inferFromVariablesInNonCycleImportsWithFlag2() async {
    addFile('''
class A { static var x = 2; }
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  A.x = /*error:INVALID_ASSIGNMENT*/"hi";
  B.y = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_inferGenericMethodType_named() async {
    var unit = await checkFile('''
class C {
  T m<T>(int a, {String b, T c}) => null;
}
main() {
 var y = new C().m(1, b: 'bbb', c: 2.0);
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.type.toString(), 'double');
  }

  test_inferGenericMethodType_positional() async {
    var unit = await checkFile('''
class C {
  T m<T>(int a, [T b]) => null;
}
main() {
  var y = new C().m(1, 2.0);
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.type.toString(), 'double');
  }

  test_inferGenericMethodType_positional2() async {
    var unit = await checkFile('''
class C {
  T m<T>(int a, [String b, T c]) => null;
}
main() {
  var y = new C().m(1, 'bbb', 2.0);
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.type.toString(), 'double');
  }

  test_inferGenericMethodType_required() async {
    var unit = await checkFile('''
class C {
  T m<T>(T x) => x;
}
main() {
  var y = new C().m(42);
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.type.toString(), 'int');
  }

  test_inferListLiteralNestedInMapLiteral() async {
    await checkFileElement(r'''
class Resource {}
class Folder extends Resource {}

Resource getResource(String str) => null;

class Foo<T> {
  Foo(T t);
}

main() {
  // List inside map
  var map = <String, List<Folder>>{
    'pkgA': /*info:INFERRED_TYPE_LITERAL*/[/*info:DOWN_CAST_IMPLICIT*/getResource('/pkgA/lib/')],
    'pkgB': /*info:INFERRED_TYPE_LITERAL*/[/*info:DOWN_CAST_IMPLICIT*/getResource('/pkgB/lib/')]
  };
  // Also try map inside list
  var list = <Map<String, Folder>>[
    /*info:INFERRED_TYPE_LITERAL*/{ 'pkgA': /*info:DOWN_CAST_IMPLICIT*/getResource('/pkgA/lib/') },
    /*info:INFERRED_TYPE_LITERAL*/{ 'pkgB': /*info:DOWN_CAST_IMPLICIT*/getResource('/pkgB/lib/') },
  ];
  // Instance creation too
  var foo = new Foo<List<Folder>>(
    /*info:INFERRED_TYPE_LITERAL*/[/*info:DOWN_CAST_IMPLICIT*/getResource('/pkgA/lib/')]
  );
}
''');
  }

  test_inferLocalFunctionReturnType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26414
    var unit = await checkFile(r'''
main() {
  f0() => 42;
  f1() async => 42;

  f2 /*info:INFERRED_TYPE_CLOSURE*/() { return 42; }
  f3 /*info:INFERRED_TYPE_CLOSURE*/() async { return 42; }
  f4 /*info:INFERRED_TYPE_CLOSURE*/() sync* { yield 42; }
  f5 /*info:INFERRED_TYPE_CLOSURE*/() async* { yield 42; }

  num f6() => 42;

  f7() => f7();
  f8() => /*error:REFERENCED_BEFORE_DECLARATION*/f9();
  f9() => f5();
}
''');
    expect(findLocalFunction(unit, 'f0').type.toString(), '() → int');
    expect(findLocalFunction(unit, 'f1').type.toString(), '() → Future<int>');

    expect(findLocalFunction(unit, 'f2').type.toString(), '() → int');
    expect(findLocalFunction(unit, 'f3').type.toString(), '() → Future<int>');
    expect(findLocalFunction(unit, 'f4').type.toString(), '() → Iterable<int>');
    expect(findLocalFunction(unit, 'f5').type.toString(), '() → Stream<int>');

    expect(findLocalFunction(unit, 'f6').type.toString(), '() → num');

    // Recursive cases: these infer in declaration order.
    expect(findLocalFunction(unit, 'f7').type.toString(), '() → dynamic');
    expect(findLocalFunction(unit, 'f8').type.toString(), '() → dynamic');
    expect(findLocalFunction(unit, 'f9').type.toString(), '() → Stream<int>');
  }

  test_inferParameterType_setter_fromField() async {
    var mainUnit = await checkFileElement('''
class C extends D {
  set foo(x) {}
}
class D {
  int foo;
}
''');
    var f = mainUnit.getType('C').accessors[0];
    expect(f.type.toString(), '(int) → void');
  }

  test_inferParameterType_setter_fromSetter() async {
    var mainUnit = await checkFileElement('''
class C extends D {
  set foo(x) {}
}
class D {
  set foo(int x) {}
}
''');
    var f = mainUnit.getType('C').accessors[0];
    expect(f.type.toString(), '(int) → void');
  }

  test_inferred_nonstatic_field_depends_on_static_field_complex() async {
    var mainUnit = await checkFileElement('''
class C {
  static var x = 'x';
  var y = /*info:INFERRED_TYPE_LITERAL*/{
    'a': /*info:INFERRED_TYPE_LITERAL*/{'b': 'c'},
    'd': /*info:INFERRED_TYPE_LITERAL*/{'e': x}
  };
}
''');
    var x = mainUnit.getType('C').fields[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'String');
    var y = mainUnit.getType('C').fields[1];
    expect(y.name, 'y');
    expect(y.type.toString(), 'Map<String, Map<String, String>>');
  }

  test_inferred_nonstatic_field_depends_on_toplevel_var_simple() async {
    var mainUnit = await checkFileElement('''
var x = 'x';
class C {
  var y = x;
}
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'String');
    var y = mainUnit.getType('C').fields[0];
    expect(y.name, 'y');
    expect(y.type.toString(), 'String');
  }

  test_inferredInitializingFormalChecksDefaultValue() async {
    await checkFileElement('''
class Foo {
  var x = 1;
  Foo([this.x = /*error:INVALID_ASSIGNMENT*/"1"]);
}''');
  }

  test_inferredType_blockClosure_noArgs_noReturn() async {
    var unit = await checkFile('''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() {};
}
''');
    var f = findLocalVariable(unit, 'f');
    expect(f.type.toString(), '() → Null');
  }

  test_inferredType_cascade() async {
    var mainUnit = await checkFileElement('''
class A {
  int a;
  List<int> b;
  void m() {}
}
var v = new A()..a = 1..b.add(2)..m();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'A');
  }

  test_inferredType_customBinaryOp() async {
    var mainUnit = await checkFileElement('''
class C {
  bool operator*(C other) => true;
}
C c;
var x = c*c;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_customBinaryOp_viaInterface() async {
    var mainUnit = await checkFileElement('''
class I {
  bool operator*(C other) => true;
}
abstract class C implements I {}
C c;
var x = c*c;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_customIndexOp() async {
    var unit = await checkFile('''
class C {
  bool operator[](int index) => true;
}
main() {
  C c;
  var x = c[0];
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_customIndexOp_viaInterface() async {
    var unit = await checkFile('''
class I {
  bool operator[](int index) => true;
}
abstract class C implements I {}
main() {
  C c;
  var x = c[0];
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_customUnaryOp() async {
    var mainUnit = await checkFileElement('''
class C {
  bool operator-() => true;
}
C c;
var x = -c;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_customUnaryOp_viaInterface() async {
    var mainUnit = await checkFileElement('''
class I {
  bool operator-() => true;
}
abstract class C implements I {}
C c;
var x = -c;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_extractMethodTearOff() async {
    var mainUnit = await checkFileElement('''
class C {
  bool g() => true;
}
C f() => null;
var x = f().g;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), '() → bool');
  }

  test_inferredType_extractMethodTearOff_viaInterface() async {
    var mainUnit = await checkFileElement('''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
var x = f().g;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), '() → bool');
  }

  test_inferredType_fromTopLevelExecutableTearoff() async {
    var mainUnit = await checkFileElement('''
var v = print;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(Object) → void');
  }

  test_inferredType_invokeMethod() async {
    var mainUnit = await checkFileElement('''
class C {
  bool g() => true;
}
C f() => null;
var x = f().g();
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_invokeMethod_viaInterface() async {
    var mainUnit = await checkFileElement('''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
var x = f().g();
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  test_inferredType_isEnum() async {
    var mainUnit = await checkFileElement('''
enum E { v1 }
final x = E.v1;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'E');
  }

  test_inferredType_isEnumValues() async {
    var mainUnit = await checkFileElement('''
enum E { v1 }
final x = E.values;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'List<E>');
  }

  test_inferredType_isTypedef() async {
    var mainUnit = await checkFileElement('''
typedef void F();
final x = <String, F>{};
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<String, () → void>');
  }

  test_inferredType_isTypedef_parameterized() async {
    var mainUnit = await checkFileElement('''
typedef T F<T>();
final x = <String, F<int>>{};
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<String, () → int>');
  }

  test_inferredType_viaClosure_multipleLevelsOfNesting() async {
    var mainUnit = await checkFileElement('''
class C {
  static final f = (bool b) => (int i) => /*info:INFERRED_TYPE_LITERAL*/{i: b};
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → (int) → Map<int, bool>');
  }

  test_inferredType_viaClosure_typeDependsOnArgs() async {
    var mainUnit = await checkFileElement('''
class C {
  static final f = (bool b) => b;
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → bool');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_field() async {
    var mainUnit = await checkFileElement('''
class C {
  static final f = (bool b) => 1;
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → int');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_topLevel() async {
    var mainUnit = await checkFileElement('final f = (bool b) => 1;');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '(bool) → int');
  }

  test_inferReturnOfStatementLambda() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26139
    await checkFileElement(r'''
List<String> strings() {
  var stuff = [].expand(/*info:INFERRED_TYPE_CLOSURE*/(i) {
    return <String>[];
  });
  return stuff.toList();
}
  ''');
  }

  test_inferStaticsTransitively() async {
    addFile('''
final b1 = 2;
''', name: '/b.dart');
    addFile('''
import 'main.dart';
import 'b.dart';
final a1 = m2;
class A {
  static final a2 = b1;
}
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
final m1 = a1;
final m2 = A.a2;

foo() {
  int i;
  i = m1;
}
''');
  }

  test_inferStaticsTransitively2() async {
    await checkFileElement('''
const x1 = 1;
final x2 = 1;
final y1 = x1;
final y2 = x2;

foo() {
  int i;
  i = y1;
  i = y2;
}
''');
  }

  test_inferStaticsTransitively3() async {
    addFile('''
const a1 = 3;
const a2 = 4;
class A {
  static const a3 = null;
}
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart' show a1, A;
import 'a.dart' as p show a2, A;
const t1 = 1;
const t2 = t1;
const t3 = a1;
const t4 = p.a2;
const t5 = A.a3;
const t6 = p.A.a3;

foo() {
  int i;
  i = t1;
  i = t2;
  i = t3;
  i = t4;
}
''');
  }

  test_inferStaticsWithMethodInvocations() async {
    addFile('''
m3(String a, String b, [a1,a2]) {}
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';
class T {
  static final T foo = m1(m2(m3('', '')));
  static T m1(String m) { return null; }
  static String m2(e) { return ''; }
}
''');
  }

  test_inferTypeOnOverriddenFields2() async {
    await checkFileElement('''
class A {
  int x = 2;
}

class B extends A {
  get x => 3;
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/new B().x;
  int z = new B().x;
}
''');
  }

  test_inferTypeOnOverriddenFields4() async {
    await checkFileElement('''
class A {
  final int x = 2;
}

class B implements A {
  get x => 3;
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/new B().x;
  int z = new B().x;
}
''');
  }

  test_inferTypeOnVar() async {
    // Error also expected when declared type is `int`.
    await checkFileElement('''
test1() {
  int x = 3;
  x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_inferTypeOnVar2() async {
    await checkFileElement('''
test2() {
  var x = 3;
  x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_inferTypeOnVarFromField() async {
    await checkFileElement('''
class A {
  int x = 0;

  test1() {
    var a = x;
    a = /*error:INVALID_ASSIGNMENT*/"hi";
    a = 3;
    var b = y;
    b = /*error:INVALID_ASSIGNMENT*/"hi";
    b = 4;
    var c = z;
    c = /*error:INVALID_ASSIGNMENT*/"hi";
    c = 4;
  }

  int y; // field def after use
  final z = 42; // should infer `int`
}
''');
  }

  test_inferTypeOnVarFromTopLevel() async {
    await checkFileElement('''
int x = 0;

test1() {
  var a = x;
  a = /*error:INVALID_ASSIGNMENT*/"hi";
  a = 3;
  var b = y;
  b = /*error:INVALID_ASSIGNMENT*/"hi";
  b = 4;
  var c = z;
  c = /*error:INVALID_ASSIGNMENT*/"hi";
  c = 4;
}

int y = 0; // field def after use
final z = 42; // should infer `int`
''');
  }

  test_inferTypeRegardlessOfDeclarationOrderOrCycles() async {
    addFile('''
import 'main.dart';

class B extends A { }
''', name: '/b.dart');
    await checkFileElement('''
import 'b.dart';
class C extends B {
  get x => null;
}
class A {
  int get x => 0;
}
foo() {
  int y = new C().x;
  String z = /*error:INVALID_ASSIGNMENT*/new C().x;
}
''');
  }

  test_inferTypesOnGenericInstantiations_3() async {
    await checkFileElement('''
class A<T> {
  final T x = null;
  final T w = null;
}

class B implements A<int> {
  get x => 3;
  get w => /*error:RETURN_OF_INVALID_TYPE*/"hello";
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/new B().x;
  int z = new B().x;
}
''');
  }

  test_inferTypesOnGenericInstantiations_4() async {
    await checkFileElement('''
class A<T> {
  T x;
}

class B<E> extends A<E> {
  E y;
  get x => y;
}

foo() {
  int y = /*error:INVALID_ASSIGNMENT*/new B<String>().x;
  String z = new B<String>().x;
}
''');
  }

  test_inferTypesOnGenericInstantiations_5() async {
    await checkFileElement('''
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

  m(a, f(v, E e)) {}
}

foo () {
  int y = /*error:INVALID_ASSIGNMENT*/new B().m(null, null);
  String z = new B().m(null, null);
}
''');
  }

  test_inferTypesOnGenericInstantiations_infer() async {
    await checkFileElement('''
class A<T> {
  final T x = null;
}

class B implements A<int> {
  /*error:INVALID_METHOD_OVERRIDE*/dynamic get x => 3;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/new B().x;
  int z = /*info:DYNAMIC_CAST*/new B().x;
}
''');
  }

  test_inferTypesOnGenericInstantiationsInLibraryCycle() async {
    // Note: this is a regression test for a non-deterministic behavior we used to
    // have with inference in library cycles. If you see this test flake out,
    // change `test` to `skip_test` and reopen bug #48.
    addFile('''
import 'main.dart';
abstract class I<E> {
  A<E> m(a, String f(v, int e));
}
''', name: '/a.dart');
    await checkFileElement('''
import 'a.dart';

abstract class A<E> implements I<E> {
  const A();

  final E value = null;
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, int e)) {}
}

foo () {
  int y = /*error:INVALID_ASSIGNMENT*/new B<String>().m(null, null).value;
  String z = new B<String>().m(null, null).value;
}
''');
  }

  test_inferTypesOnLoopIndices_forEachLoop() async {
    await checkFileElement('''
class Foo {
  int bar = 42;
}

class Bar<T extends Iterable<String>> {
  void foo(T t) {
    for (var i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/i;
    }
  }
}

class Baz<T, E extends Iterable<T>, S extends E> {
  void foo(S t) {
    for (var i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/i;
      T y = i;
    }
  }
}

test() {
  var list = <Foo>[];
  for (var x in list) {
    String y = /*error:INVALID_ASSIGNMENT*/x;
  }

  for (dynamic x in list) {
    String y = /*info:DYNAMIC_CAST*/x;
  }

  for (String x in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/list) {
    String y = x;
  }

  var z;
  for(z in list) {
    String y = /*info:DYNAMIC_CAST*/z;
  }

  Iterable iter = list;
  for (Foo /*info:DYNAMIC_CAST*/x in iter) {
    var y = x;
  }

  dynamic iter2 = list;
  for (Foo /*info:DYNAMIC_CAST*/x in /*info:DYNAMIC_CAST*/iter2) {
    var y = x;
  }

  var map = <String, Foo>{};
  // Error: map must be an Iterable.
  for (var x in /*error:FOR_IN_OF_INVALID_TYPE*/map) {
    String y = /*info:DYNAMIC_CAST*/x;
  }

  // We're not properly inferring that map.keys is an Iterable<String>
  // and that x is a String.
  for (var x in map.keys) {
    String y = x;
  }
}
''');
  }

  test_inferTypesOnLoopIndices_forLoopWithInference() async {
    await checkFileElement('''
test() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
  }
}
''');
  }

  test_inferVariableVoid() async {
    var mainUnit = await checkFileElement('''
void f() {}
var x = /*info:USE_OF_VOID_RESULT*/f();
  ''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'void');
  }

  test_instantiateToBounds_generic2_hasBound_definedAfter() async {
    var unit = await checkFileElement(r'''
class B<T extends /*error:NOT_INSTANTIATED_BOUND*/A> {}
class A<T extends int> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  test_instantiateToBounds_generic2_hasBound_definedBefore() async {
    var unit = await checkFileElement(r'''
class A<T extends int> {}
class B<T extends /*error:NOT_INSTANTIATED_BOUND*/A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  test_instantiateToBounds_generic2_noBound() async {
    var unit = await checkFileElement(r'''
class A<T> {}
class B<T extends A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  test_instantiateToBounds_generic_hasBound_definedAfter() async {
    var unit = await checkFileElement(r'''
A v = null;
class A<T extends int> {}
''');
    expect(unit.topLevelVariables[0].type.toString(), 'A<int>');
  }

  test_instantiateToBounds_generic_hasBound_definedBefore() async {
    var unit = await checkFileElement(r'''
class A<T extends int> {}
A v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'A<int>');
  }

  test_instantiateToBounds_invokeConstructor_noBound() async {
    var unit = await checkFile('''
class C<T> {}
main() {
  var v = new C();
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'C<dynamic>');
  }

  test_instantiateToBounds_invokeConstructor_typeArgsExact() async {
    var unit = await checkFileElement('''
class C<T extends num> {}
var x = new C<int>();
''');
    expect(unit.topLevelVariables[0].type.toString(), 'C<int>');
  }

  test_instantiateToBounds_notGeneric() async {
    var unit = await checkFileElement(r'''
class A {}
class B<T extends A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A>');
  }

  test_lambdaDoesNotHavePropagatedTypeHint() async {
    await checkFileElement(r'''
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
  /*info:DYNAMIC_INVOKE*/list.map((value) => '$value');
}
  ''');
  }

  test_listLiterals() async {
    await checkFileElement(r'''
test1() {
  var x = /*info:INFERRED_TYPE_LITERAL*/[1, 2, 3];
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi');
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/4.0);
  x.add(4);
  List<num> y = x;
}
test2() {
  var x = /*info:INFERRED_TYPE_LITERAL*/[1, 2.0, 3];
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi');
  x.add(4.0);
  List<int> y = /*info:ASSIGNMENT_CAST*/x;
}
''');
  }

  test_listLiterals_topLevel() async {
    await checkFileElement(r'''
var x1 = /*info:INFERRED_TYPE_LITERAL*/[1, 2, 3];
test1() {
  x1.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi');
  x1.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/4.0);
  x1.add(4);
  List<num> y = x1;
}
var x2 = /*info:INFERRED_TYPE_LITERAL*/[1, 2.0, 3];
test2() {
  x2.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi');
  x2.add(4.0);
  List<int> y = /*info:ASSIGNMENT_CAST*/x2;
}
''');
  }

  test_listLiteralsCanInferNull_topLevel() async {
    var unit = await checkFileElement(r'''
var x = /*info:INFERRED_TYPE_LITERAL*/[null];
''');
    var x = unit.topLevelVariables[0];
    expect(x.type.toString(), 'List<Null>');
  }

  test_listLiteralsCanInferNullBottom() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
test1() {
  var x = /*info:INFERRED_TYPE_LITERAL*/[null];
  x.add(/*error:INVALID_CAST_LITERAL*/42);
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'List<Null>');
  }

  test_mapLiterals() async {
    await checkFileElement(r'''
test1() {
  var x = /*info:INFERRED_TYPE_LITERAL*/{ 1: 'x', 2: 'y' };
  x[3] = 'z';
  x[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi'] = 'w';
  x[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/4.0] = 'u';
  x[3] = /*error:INVALID_ASSIGNMENT*/42;
  Map<num, String> y = x;
}

test2() {
  var x = /*info:INFERRED_TYPE_LITERAL*/{ 1: 'x', 2: 'y', 3.0: new RegExp('.') };
  x[3] = 'z';
  x[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi'] = 'w';
  x[4.0] = 'u';
  x[3] = /*error:INVALID_ASSIGNMENT*/42;
  Pattern p = null;
  x[2] = p;
  Map<int, String> y = /*info:ASSIGNMENT_CAST*/x;
}
''');
  }

  test_mapLiterals_topLevel() async {
    await checkFileElement(r'''
var x1 = /*info:INFERRED_TYPE_LITERAL*/{ 1: 'x', 2: 'y' };
test1() {
  x1[3] = 'z';
  x1[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi'] = 'w';
  x1[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/4.0] = 'u';
  x1[3] = /*error:INVALID_ASSIGNMENT*/42;
  Map<num, String> y = x1;
}

var x2 = /*info:INFERRED_TYPE_LITERAL*/{ 1: 'x', 2: 'y', 3.0: new RegExp('.') };
test2() {
  x2[3] = 'z';
  x2[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi'] = 'w';
  x2[4.0] = 'u';
  x2[3] = /*error:INVALID_ASSIGNMENT*/42;
  Pattern p = null;
  x2[2] = p;
  Map<int, String> y = /*info:ASSIGNMENT_CAST*/x2;
}
''');
  }

  test_mapLiteralsCanInferNull() async {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = await checkFile(r'''
test1() {
  var x = /*info:INFERRED_TYPE_LITERAL*/{ null: null };
  x[/*error:INVALID_CAST_LITERAL*/3] = /*error:INVALID_CAST_LITERAL*/'z';
}
''');
    var x = findLocalVariable(unit, 'x');
    expect(x.type.toString(), 'Map<Null, Null>');
  }

  test_mapLiteralsCanInferNull_topLevel() async {
    var unit = await checkFileElement(r'''
var x = /*info:INFERRED_TYPE_LITERAL*/{ null: null };
''');
    var x = unit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<Null, Null>');
  }

  test_methodCall_withTypeArguments_instanceMethod() async {
    var mainUnit = await checkFileElement('''
class C {
  D<T> f<T>() => null;
}
class D<T> {}
var f = new C().f<int>();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  test_methodCall_withTypeArguments_instanceMethod_identifierSequence() async {
    var mainUnit = await checkFileElement('''
class C {
  D<T> f<T>() => null;
}
class D<T> {}
C c;
var f = c.f<int>();
''');
    var v = mainUnit.topLevelVariables[1];
    expect(v.name, 'f');
    expect(v.type.toString(), 'D<int>');
  }

  test_methodCall_withTypeArguments_staticMethod() async {
    var mainUnit = await checkFileElement('''
class C {
  static D<T> f<T>() => null;
}
class D<T> {}
var f = C.f<int>();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  test_methodCall_withTypeArguments_topLevelFunction() async {
    var mainUnit = await checkFileElement('''
D<T> f<T>() => null;
class D<T> {}
var g = f<int>();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  test_noErrorWhenDeclaredTypeIsNumAndAssignedNull() async {
    await checkFileElement('''
test1() {
  num x = 3;
  x = null;
}
''');
  }

  test_nullCoalescingOperator() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26552
    await checkFileElement(r'''
main() {
  List<int> x;
  var y = x ?? /*info:INFERRED_TYPE_LITERAL*/[];
  List<int> z = y;
}
''');
    // Don't do anything if we already have a context type.
    var unit = await checkFile(r'''
main() {
  List<int> x;
  List<num> y = x ?? /*info:INFERRED_TYPE_LITERAL*/[];
}
''');
    var y = findLocalVariable(unit, 'y');
    expect(y.initializer.returnType.toString(), 'List<num>');
  }

  test_nullLiteralShouldNotInferAsBottom() async {
    // Regression test for https://github.com/dart-lang/dev_compiler/issues/47
    await checkFileElement(r'''
var h = null;
void foo(int f(Object _)) {}

main() {
  var f = (Object x) => null;
  String y = /*info:DYNAMIC_CAST*/f(42);

  f = /*info:INFERRED_TYPE_CLOSURE*/(x) => 'hello';

  var g = null;
  g = 'hello';
  (/*info:DYNAMIC_INVOKE*/g.foo());

  h = 'hello';
  (/*info:DYNAMIC_INVOKE*/h.foo());

  foo(/*info:INFERRED_TYPE_CLOSURE*/(x) => null);
  foo(/*info:INFERRED_TYPE_CLOSURE*/(x) => throw "not implemented");
}
''');
  }

  test_propagateInferenceToFieldInClass() async {
    await checkFileElement('''
class A {
  int x = 2;
}

test() {
  var a = new A();
  A b = a;                      // doesn't require down cast
  print(a.x);     // doesn't require dynamic invoke
  print(a.x + 2); // ok to use in bigger expression
}
''');
  }

  test_propagateInferenceToFieldInClassDynamicWarnings() async {
    await checkFileElement('''
class A {
  int x = 2;
}

test() {
  dynamic a = new A();
  A b = /*info:DYNAMIC_CAST*/a;
  print(/*info:DYNAMIC_INVOKE*/a.x);
  print(/*info:DYNAMIC_INVOKE*/(/*info:DYNAMIC_INVOKE*/a.x) + 2);
}
''');
  }

  test_propagateInferenceTransitively() async {
    await checkFileElement('''
class A {
  int x = 2;
}

test5() {
  var a1 = new A();
  a1.x = /*error:INVALID_ASSIGNMENT*/"hi";

  A a2 = new A();
  a2.x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  test_propagateInferenceTransitively2() async {
    await checkFileElement('''
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
    var mainUnit = await checkFileElement('''
typedef void F();
final x = F;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Type');
  }

  test_refineBinaryExpressionType_typeParameter_T_double() async {
    await checkFileElement('''
class C<T extends num> {
  T a;

  void op(double b) {
    double r1 = a + b;
    double r2 = a - b;
    double r3 = a * b;
    double r4 = a / b;
  }
}
''');
  }

  test_refineBinaryExpressionType_typeParameter_T_int() async {
    await checkFileElement('''
class C<T extends num> {
  T a;

  void op(int b) {
    T r1 = a + b;
    T r2 = a - b;
    T r3 = a * b;
  }

  void opEq(int b) {
    a += b;
    a -= b;
    a *= b;
  }
}
''');
  }

  test_refineBinaryExpressionType_typeParameter_T_T() async {
    await checkFileElement('''
class C<T extends num> {
  T a;

  void op(T b) {
    T r1 = a + b;
    T r2 = a - b;
    T r3 = a * b;
  }

  void opEq(T b) {
    a += b;
    a -= b;
    a *= b;
  }
}
''');
  }

  test_staticMethod_tearoff() async {
    var mainUnit = await checkFileElement('''
const v = C.f;
class C {
  static int f(String s) => null;
}
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(String) → int');
  }

  test_unsafeBlockClosureInference_closureCall() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26962
    var unit = await checkFile('''
main() {
  var v = ((x) => 1.0)(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.name, 'v');
    expect(v.type.toString(), 'double');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitDynamicParam() async {
    var mainUnit = await checkFileElement('''
class C<T> {
  C(T x());
}
var v = new C<dynamic>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'C<dynamic>');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitTypeParam() async {
    var mainUnit = await checkFileElement('''
class C<T> {
  C(T x());
}
var v = new C<int>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_implicitTypeParam() async {
    var unit = await checkFile('''
class C<T> {
  C(T x());
}
main() {
  var v = /*info:INFERRED_TYPE_ALLOCATION*/new C(
    /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    });
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.name, 'v');
    expect(v.type.toString(), 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_noTypeParam() async {
    var mainUnit = await checkFileElement('''
class C {
  C(x());
}
var v = new C(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'C');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam() async {
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<dynamic>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<dynamic>');
  }

  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr1() async {
    // Note: (f/*<dynamic>*/) is nort properly resulting in an instantiated
    // function type due to dartbug.com/25824.
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f<dynamic>)(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2() async {
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<dynamic>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam() async {
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<int>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr1() async {
    // TODO(paulberry): for some reason (f/*<int>) is nort properly resulting
    // in an instantiated function type.
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f/int>)(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2() async {
    var mainUnit = await checkFileElement('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<int>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam() async {
    var unit = await checkFile('''
main() {
  var v = f(
    /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr() async {
    var unit = await checkFile('''
main() {
  var v = (f)(
    /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam() async {
    var unit = await checkFile('''
main() {
  var v = f(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
}
double f(x) => 1.0;
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'double');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam_viaExpr() async {
    var unit = await checkFile('''
main() {
  var v = (f)(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
}
double f(x) => 1.0;
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'double');
  }

  test_unsafeBlockClosureInference_inList_dynamic() async {
    var unit = await checkFile('''
main() {
  var v = <dynamic>[/*info:INFERRED_TYPE_CLOSURE*/() { return 1; }];
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_inList_typed() async {
    var unit = await checkFile('''
typedef int F();
main() {
  var v = <F>[/*info:INFERRED_TYPE_CLOSURE*/() { return 1; }];
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<() → int>');
  }

  test_unsafeBlockClosureInference_inList_untyped() async {
    var unit = await checkFile('''
main() {
  var v = /*info:INFERRED_TYPE_LITERAL*/[
    /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    }];
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<() → int>');
  }

  test_unsafeBlockClosureInference_inMap_dynamic() async {
    var unit = await checkFile('''
main() {
  var v = <int, dynamic>{1: /*info:INFERRED_TYPE_CLOSURE*/() { return 1; }};
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'Map<int, dynamic>');
  }

  test_unsafeBlockClosureInference_inMap_typed() async {
    var unit = await checkFile('''
typedef int F();
main() {
  var v = <int, F>{1: /*info:INFERRED_TYPE_CLOSURE*/() { return 1; }};
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'Map<int, () → int>');
  }

  test_unsafeBlockClosureInference_inMap_untyped() async {
    var unit = await checkFile('''
main() {
  var v = /*info:INFERRED_TYPE_LITERAL*/{
    1: /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    }};
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'Map<int, () → int>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitDynamicParam() async {
    var unit = await checkFile('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<dynamic>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitTypeParam() async {
    var unit = await checkFile('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<int>(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_implicitTypeParam() async {
    var unit = await checkFile('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f(
    /*info:INFERRED_TYPE_CLOSURE*/() {
      return 1;
    });
}
''');
    var v = findLocalVariable(unit, 'v');
    expect(v.type.toString(), 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_noTypeParam() async {
    var mainUnit = await checkFileElement('''
class C {
  double f(x) => 1.0;
}
var v = new C().f(/*info:INFERRED_TYPE_CLOSURE*/() { return 1; });
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.name, 'v');
    expect(v.type.toString(), 'double');
  }

  test_voidReturnTypeSubtypesDynamic() async {
    var unit = await checkFileElement(r'''
T run<T>(T f()) {
  print("running");
  var t = f();
  print("done running");
  return t;
}


void printRunning() { print("running"); }
var x = run<dynamic>(printRunning);
var y = /*info:USE_OF_VOID_RESULT*/run(printRunning);

main() {
  void printRunning() { print("running"); }
  var x = run<dynamic>(printRunning);
  var y = /*info:USE_OF_VOID_RESULT*/run(printRunning);
  x = 123;
  x = 'hi';
  y = /*error:INVALID_ASSIGNMENT*/123;
  y = /*error:INVALID_ASSIGNMENT*/'hi';
}
  ''');

    var x = unit.topLevelVariables[0];
    var y = unit.topLevelVariables[1];
    expect(x.type.toString(), 'dynamic');
    expect(y.type.toString(), 'void');
  }
}

@reflectiveTest
class InferredTypeTest extends AbstractStrongTest with InferredTypeMixin {
  @override
  bool get mayCheckTypesOfLocals => true;

  @override
  Future<CompilationUnitElement> checkFileElement(String content) async {
    CompilationUnit unit = await checkFile(content);
    return (unit).element;
  }
}

@reflectiveTest
class InferredTypeTest_Driver extends InferredTypeTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  bool get hasExtraTaskModelPass => false;

  @override
  test_circularReference_viaClosures() async {
    await super.test_circularReference_viaClosures();
  }

  @override
  test_circularReference_viaClosures_initializerTypes() async {
    await super.test_circularReference_viaClosures_initializerTypes();
  }

  @failingTest
  @override
  test_genericMethods_usesGreatestLowerBound_topLevel() async {
    await super.test_genericMethods_usesGreatestLowerBound_topLevel();
  }

  @failingTest
  @override
  test_listLiteralsCanInferNull_topLevel() =>
      super.test_listLiteralsCanInferNull_topLevel();

  @failingTest
  @override
  test_mapLiteralsCanInferNull_topLevel() =>
      super.test_mapLiteralsCanInferNull_topLevel();

  @failingTest
  @override
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2() async {
    await super
        .test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2();
  }

  @failingTest
  @override
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2() async {
    await super
        .test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2();
  }

  @failingTest
  @override
  test_voidReturnTypeSubtypesDynamic() async {
    await super.test_voidReturnTypeSubtypesDynamic();
  }
}
