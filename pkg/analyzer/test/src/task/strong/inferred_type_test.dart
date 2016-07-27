// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
/// Tests for type inference.
library analyzer.test.src.task.strong.inferred_type_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:unittest/unittest.dart';

import '../../../reflective_tests.dart';
import 'strong_test_helper.dart' as helper;

void main() {
  helper.initStrongModeTests();
  runReflectiveTests(InferredTypeTest);
}

abstract class InferredTypeMixin {
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
   * unit element.
   */
  CompilationUnitElement checkFile(String content);

  void test_blockBodiedLambdas_async_allReturnsAreFutures() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
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
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_async_allReturnsAreFutures_topLevel() {
    var mainUnit = checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
  if (new Random().nextBool()) {
    return new Future<int>.value(1);
  } else {
    return new Future<double>.value(2.0);
  }
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_async_allReturnsAreValues() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
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
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_async_allReturnsAreValues_topLevel() {
    var mainUnit = checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
  if (new Random().nextBool()) {
    return 1;
  } else {
    return 2.0;
  }
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_async_mixOfValuesAndFutures() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
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
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_async_mixOfValuesAndFutures_topLevel() {
    var mainUnit = checkFile(r'''
import 'dart:async';
import 'dart:math' show Random;
var f = /*info:INFERRED_TYPE_CLOSURE*/() async {
  if (new Random().nextBool()) {
    return new Future<int>.value(1);
  } else {
    return 2.0;
  }
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Future<num>');
  }

  void test_blockBodiedLambdas_asyncStar() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
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
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Stream<num>');
  }

  void test_blockBodiedLambdas_asyncStar_topLevel() {
    var mainUnit = checkFile(r'''
  import 'dart:async';
var f = /*info:INFERRED_TYPE_CLOSURE*/() async* {
  yield 1;
  Stream<double> s;
  yield* s;
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Stream<num>');
  }

  void test_blockBodiedLambdas_basic() {
    checkFile(r'''
test1() {
  List<int> o;
  var y = o.map(/*info:INFERRED_TYPE_CLOSURE,info:INFERRED_TYPE_CLOSURE*/(x) { return x + 1; });
  Iterable<int> z = y;
}
''');
  }

  void test_blockBodiedLambdas_basic_topLevel() {
    checkFile(r'''
List<int> o;
var y = o.map(/*info:INFERRED_TYPE_CLOSURE*/(x) { return x + 1; });
Iterable<int> z = y;
''');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_async() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
import 'dart:async';
main() async {
  var f = () async { return null; };
  Future y = f();
  Future<String> z = /*warning:DOWN_CAST_COMPOSITE*/f();
  String s = /*info:DYNAMIC_CAST*/await f();
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Future<dynamic>');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_async_topLevel() {
    var mainUnit = checkFile(r'''
import 'dart:async';
var f = () async { return null; };
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Future<dynamic>');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_asyncStar() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
import 'dart:async';
main() async {
  var f = () async* { yield null; };
  Stream y = f();
  Stream<String> z = /*warning:DOWN_CAST_COMPOSITE*/f();
  String s = /*info:DYNAMIC_CAST*/await f().first;
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Stream<dynamic>');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_asyncStar_topLevel() {
    var mainUnit = checkFile(r'''
import 'dart:async';
var f = () async* { yield null; };
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Stream<dynamic>');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_sync() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
var h = null;
void foo(int f(Object _)) {}

main() {
  var f = (Object x) { return null; };
  String y = /*info:DYNAMIC_CAST*/f(42);

  f = /*info:INFERRED_TYPE_CLOSURE*/(x) => 'hello';

  foo(/*info:INFERRED_TYPE_CLOSURE*/(x) { return null; });
  foo(/*info:INFERRED_TYPE_CLOSURE*/(x) { throw "not implemented"; });
}
''');

    var f = mainUnit.functions[1].localVariables[0];
    expect(f.type.toString(), '(Object) → dynamic');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_sync_topLevel() {
    var mainUnit = checkFile(r'''
var f = (Object x) { return null; };
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '(Object) → dynamic');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_syncStar() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
main() {
  var f = () sync* { yield null; };
  Iterable y = f();
  Iterable<String> z = /*warning:DOWN_CAST_COMPOSITE*/f();
  String s = /*info:DYNAMIC_CAST*/f().first;
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Iterable<dynamic>');
  }

  void test_blockBodiedLambdas_doesNotInferBottom_syncStar_topLevel() {
    var mainUnit = checkFile(r'''
var f = () sync* { yield null; };
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Iterable<dynamic>');
  }

  void test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
main() {
  String f() => null;
  var g = f;
  g = /*info:INFERRED_TYPE_CLOSURE*/() { return /*error:RETURN_OF_INVALID_TYPE*/1; };
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → String');
  }

  void
      test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference_topLevel() {
    var mainUnit = checkFile(r'''
String f() => null;
var g = f;
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → String');
  }

  void test_blockBodiedLambdas_LUB() {
    checkFile(r'''
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

  void test_blockBodiedLambdas_LUB_topLevel() {
    checkFile(r'''
import 'dart:math' show Random;
List<num> o;
var y = o.map(/*info:INFERRED_TYPE_CLOSURE*/(x) {
  if (new Random().nextBool()) {
    return x.toInt() + 1;
  } else {
    return x.toDouble();
  }
});
Iterable<num> w = y;
Iterable<int> z = /*info:ASSIGNMENT_CAST*/y;
''');
  }

  void test_blockBodiedLambdas_nestedLambdas() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    // Original feature request: https://github.com/dart-lang/sdk/issues/25487
    var mainUnit = checkFile(r'''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() {
    return /*info:INFERRED_TYPE_CLOSURE*/(int x) { return 2.0 * x; };
  };
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → (int) → double');
  }

  void test_blockBodiedLambdas_nestedLambdas_topLevel() {
    // Original feature request: https://github.com/dart-lang/sdk/issues/25487
    var mainUnit = checkFile(r'''
var f = /*info:INFERRED_TYPE_CLOSURE*/() {
  return /*info:INFERRED_TYPE_CLOSURE*/(int x) { return 2.0 * x; };
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → (int) → double');
  }

  void test_blockBodiedLambdas_noReturn() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
test1() {
  List<int> o;
  var y = o.map(/*info:INFERRED_TYPE_CLOSURE*/(x) { });
  Iterable<int> z = /*warning:DOWN_CAST_COMPOSITE*/y;
}
''');
    var f = mainUnit.functions[0].localVariables[1];
    expect(f.type.toString(), 'Iterable<dynamic>');
  }

  void test_blockBodiedLambdas_noReturn_topLevel() {
    var mainUnit = checkFile(r'''
final List<int> o = <int>[];
var y = o.map((x) { });
''');
    var f = mainUnit.topLevelVariables[1];
    expect(f.type.toString(), 'Iterable<dynamic>');
  }

  void test_blockBodiedLambdas_syncStar() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var mainUnit = checkFile(r'''
main() {
  var f = /*info:INFERRED_TYPE_CLOSURE*/() sync* {
    yield 1;
    yield* /*info:INFERRED_TYPE_LITERAL*/[3, 4.0];
  };
  Iterable<num> g = f();
  Iterable<int> h = /*info:ASSIGNMENT_CAST*/f();
}
''');
    var f = mainUnit.functions[0].localVariables[0];
    expect(f.type.toString(), '() → Iterable<num>');
  }

  void test_blockBodiedLambdas_syncStar_topLevel() {
    var mainUnit = checkFile(r'''
var f = /*info:INFERRED_TYPE_CLOSURE*/() sync* {
  yield 1;
  yield* /*info:INFERRED_TYPE_LITERAL*/[3, 4.0];
};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → Iterable<num>');
  }

  void test_bottom() {
    // When a type is inferred from the expression `null`, the inferred type is
    // `dynamic`, but the inferred type of the initializer is `bottom`.
    // TODO(paulberry): Is this intentional/desirable?
    var mainUnit = checkFile('''
var v = null;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'dynamic');
    expect(v.initializer.type.toString(), '() → <bottom>');
  }

  void test_bottom_inClosure() {
    // When a closure's return type is inferred from the expression `null`, the
    // inferred type is `dynamic`.
    var mainUnit = checkFile('''
var v = () => null;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '() → dynamic');
    expect(v.initializer.type.toString(), '() → () → dynamic');
  }

  void test_canInferAlsoFromStaticAndInstanceFieldsFlagOn() {
    addFile(
        '''
import 'b.dart';
class A {
  static final a1 = B.b1;
  final a2 = new B().b2;
}
''',
        name: '/a.dart');
    addFile(
        '''
class B {
  static final b1 = 1;
  final b2 = 1;
}
''',
        name: '/b.dart');
    checkFile('''
import "a.dart";

test1() {
  int x = 0;
  // inference in A now works.
  x = A.a1;
  x = new A().a2;
}
''');
  }

  void test_circularReference_viaClosures() {
    var mainUnit = checkFile('''
var x = () => y;
var y = () => x;
''');
    var x = mainUnit.topLevelVariables[0];
    var y = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    expect(x.type.toString(), 'dynamic');
    expect(y.type.toString(), 'dynamic');
  }

  void test_circularReference_viaClosures_initializerTypes() {
    var mainUnit = checkFile('''
var x = () => y;
var y = () => x;
''');
    var x = mainUnit.topLevelVariables[0];
    var y = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    expect(x.initializer.returnType.toString(), '() → dynamic');
    expect(y.initializer.returnType.toString(), '() → dynamic');
  }

  void test_conflictsCanHappen() {
    checkFile('''
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

  void test_conflictsCanHappen2() {
    checkFile('''
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

  void test_doNotInferOverriddenFieldsThatExplicitlySayDynamic_infer() {
    checkFile('''
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

  void test_dontInferFieldTypeWhenInitializerIsNull() {
    checkFile('''
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

  void test_dontInferTypeOnDynamic() {
    checkFile('''
test() {
  dynamic x = 3;
  x = "hi";
}
''');
  }

  void test_dontInferTypeWhenInitializerIsNull() {
    checkFile('''
test() {
  var x = null;
  x = "hi";
  x = 3;
}
''');
  }

  void test_downwardInference_miscellaneous() {
    checkFile('''
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

  void test_downwardsInferenceAnnotations() {
    checkFile('''
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

  void test_downwardsInferenceAssignmentStatements() {
    checkFile('''
void main() {
  List<int> l;
  l = /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
  l = (l = /*info:INFERRED_TYPE_LITERAL*/[1]);
}
''');
  }

  void test_downwardsInferenceAsyncAwait() {
    checkFile('''
import 'dart:async';
Future test() async {
  dynamic d;
  List<int> l0 = /*warning:DOWN_CAST_COMPOSITE should be pass*/await /*pass should be info:INFERRED_TYPE_LITERAL*/[d];
  List<int> l1 = await /*info:INFERRED_TYPE_ALLOCATION*/new Future.value(/*info:INFERRED_TYPE_LITERAL*/[/*info:DYNAMIC_CAST*/d]);
}
''');
  }

  void test_downwardsInferenceForEach() {
    checkFile('''
import 'dart:async';
Future main() async {
  for(int x in /*info:INFERRED_TYPE_LITERAL*/[1, 2, 3]) {}
  await for(int x in /*info:INFERRED_TYPE_ALLOCATION*/new Stream()) {}
}
''');
  }

  void test_downwardsInferenceInitializingFormalDefaultFormal() {
    checkFile('''
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

  void test_downwardsInferenceOnConstructorArguments_inferDownwards() {
    checkFile('''
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

  void test_downwardsInferenceOnFunctionArguments_inferDownwards() {
    checkFile('''
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

  void test_downwardsInferenceOnFunctionExpressions() {
    checkFile('''
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
    Function2<int, String> l3 = /*info:INFERRED_TYPE_CLOSURE*/(x) => /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/x.substring(3);
    Function2<String, String> l4 = /*info:INFERRED_TYPE_CLOSURE*/(x) => x.substring(3);
  }
}
''');
  }

  void test_downwardsInferenceOnFunctionOfTUsingTheT() {
    checkFile('''
void main () {
  {
    /*=T*/ f/*<T>*/(/*=T*/ x) => null;
    var v1 = f;
    v1 = /*info:INFERRED_TYPE_CLOSURE*//*<S>*/(x) => x;
  }
  {
    /*=List<T>*/ f/*<T>*/(/*=T*/ x) => null;
    var v2 = f;
    v2 = /*info:INFERRED_TYPE_CLOSURE*//*<S>*/(x) => /*info:INFERRED_TYPE_LITERAL*/[x];
    Iterable<int> r = v2(42);
    Iterable<String> s = v2('hello');
    Iterable<List<int>> t = v2(<int>[]);
    Iterable<num> u = v2(42);
    Iterable<num> v = v2/*<num>*/(42);
  }
}
''');
  }

  void test_downwardsInferenceOnGenericConstructorArguments_inferDownwards() {
    checkFile('''
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
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"]]);
  new F3(/*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"],
                                        /*info:INFERRED_TYPE_LITERAL*/[3]]);

  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/[3]]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"]]);
  new F4(a: /*info:INFERRED_TYPE_LITERAL*/[/*info:INFERRED_TYPE_LITERAL*/["hello"],
                                           /*info:INFERRED_TYPE_LITERAL*/[3]]);
}
''');
  }

  void test_downwardsInferenceOnGenericFunctionExpressions() {
    checkFile('''
void main () {
  {
    String f/*<S>*/(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(int x) => null;
    v = /*<T>*/(int x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*//*<T>*/(String x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*//*<T>*/(int x) => 3;
    v = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(int x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
  }
  {
    String f/*<S>*/(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => null;
    v = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => "hello";
    v = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*//*<T>*/(x) => 3;
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) {return /*error:RETURN_OF_INVALID_TYPE*/3;};
    v = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) {return /*error:RETURN_OF_INVALID_TYPE*/x;};
  }
  {
    List<String> f/*<S>*/(int x) => null;
    var v = f;
    v = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(int x) => null;
    v = /*<T>*/(int x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    v = /*error:INVALID_ASSIGNMENT*//*<T>*/(String x) => /*info:INFERRED_TYPE_LITERAL*/["hello"];
    v = /*<T>*/(int x) => /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];
    v = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(int x) {return /*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/3];};
  }
  {
    int int2int/*<S>*/(int x) => null;
    String int2String/*<T>*/(int x) => null;
    String string2String/*<T>*/(String x) => null;
    var x = int2int;
    x = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => x;
    x = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => x+1;
    var y = int2String;
    y = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*//*<T>*/(x) => x;
    y = /*info:INFERRED_TYPE_CLOSURE, info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => /*info:DYNAMIC_INVOKE, info:DYNAMIC_CAST*/x.substring(3);
    var z = string2String;
    z = /*info:INFERRED_TYPE_CLOSURE*//*<T>*/(x) => x.substring(3);
  }
}
''');
  }

  void test_downwardsInferenceOnInstanceCreations_inferDownwards() {
    checkFile('''
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
    A<int, String> a4 = /*error:STATIC_TYPE_ERROR*/new A<int, dynamic>(3, "hello");
    A<int, String> a5 = /*error:STATIC_TYPE_ERROR*/new A<dynamic, dynamic>.named(3, "hello");
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
    A<int, String> a4 = /*error:STATIC_TYPE_ERROR*/new B<String, dynamic>("hello", 3);
    A<int, String> a5 = /*error:STATIC_TYPE_ERROR*/new B<dynamic, dynamic>.named("hello", 3);
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
    A<int, int> a4 = /*error:STATIC_TYPE_ERROR*/new C<dynamic>(3);
    A<int, int> a5 = /*error:STATIC_TYPE_ERROR*/new C<dynamic>.named(3);
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
    A<int, String> a4 = /*error:STATIC_TYPE_ERROR*/new D<num, dynamic>("hello");
    A<int, String> a5 = /*error:STATIC_TYPE_ERROR*/new D<dynamic, dynamic>.named("hello");
  }
  {
    A<int, String> a0 = /*info:INFERRED_TYPE_ALLOCATION*/new D(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
    A<int, String> a1 = /*info:INFERRED_TYPE_ALLOCATION*/new D.named(
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
  }
  { // Currently we only allow variable constraints.  Test that we reject.
    A<C<int>, String> a0 = /*error:STATIC_TYPE_ERROR*/new E("hello");
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

  void test_downwardsInferenceOnListLiterals_inferDownwards() {
    checkFile('''
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
    List<dynamic> l1 = /*info:INFERRED_TYPE_LITERAL*/[3];
    List<dynamic> l2 = /*info:INFERRED_TYPE_LITERAL*/["hello"];
    List<dynamic> l3 = /*info:INFERRED_TYPE_LITERAL*/["hello", 3];
  }
  {
    List<int> l0 = /*error:STATIC_TYPE_ERROR*/<num>[];
    List<int> l1 = /*error:STATIC_TYPE_ERROR*/<num>[3];
    List<int> l2 = /*error:STATIC_TYPE_ERROR*/<num>[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello"];
    List<int> l3 = /*error:STATIC_TYPE_ERROR*/<num>[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/"hello", 3];
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

  void test_downwardsInferenceOnListLiterals_inferIfValueTypesMatchContext() {
    checkFile(r'''
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

  void test_downwardsInferenceOnMapLiterals() {
    checkFile('''
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
    Map<dynamic, dynamic> l1 = /*info:INFERRED_TYPE_LITERAL*/{3: "hello"};
    Map<dynamic, dynamic> l2 = /*info:INFERRED_TYPE_LITERAL*/{"hello": "hello"};
    Map<dynamic, dynamic> l3 = /*info:INFERRED_TYPE_LITERAL*/{3: 3};
    Map<dynamic, dynamic> l4 = /*info:INFERRED_TYPE_LITERAL*/{3:"hello", "hello": 3};
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
    Map<int, String> l0 = /*error:STATIC_TYPE_ERROR*/<num, dynamic>{};
    Map<int, String> l1 = /*error:STATIC_TYPE_ERROR*/<num, dynamic>{3: "hello"};
    Map<int, String> l3 = /*error:STATIC_TYPE_ERROR*/<num, dynamic>{3: 3};
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

  void test_downwardsInferenceYieldYieldStar() {
    checkFile('''
import 'dart:async';
Stream<List<int>> foo() async* {
  yield /*info:INFERRED_TYPE_LITERAL*/[];
  yield /*error:YIELD_OF_INVALID_TYPE*/new Stream();
  yield* /*error:YIELD_OF_INVALID_TYPE*/[];
  yield* /*info:INFERRED_TYPE_ALLOCATION*/new Stream();
}

Iterable<Map<int, int>> bar() sync* {
  yield /*info:INFERRED_TYPE_LITERAL*/{};
  yield /*error:YIELD_OF_INVALID_TYPE*/new List();
  yield* /*error:YIELD_OF_INVALID_TYPE*/{};
  yield* /*info:INFERRED_TYPE_ALLOCATION*/new List();
}
  ''');
  }

  void test_fieldRefersToStaticGetter() {
    var mainUnit = checkFile('''
class C {
  final x = _x;
  static int get _x => null;
}
''');
    var x = mainUnit.types[0].fields[0];
    expect(x.type.toString(), 'int');
  }

  void test_fieldRefersToTopLevelGetter() {
    var mainUnit = checkFile('''
class C {
  final x = y;
}
int get y => null;
''');
    var x = mainUnit.types[0].fields[0];
    expect(x.type.toString(), 'int');
  }

  void test_futureThen() {
    checkFile('''
import 'dart:async';
Future f;
Future<int> t1 = f.then((_) => new Future<int>.value(42));
''');
  }

  void test_genericMethods_basicDownwardInference() {
    checkFile(r'''
/*=T*/ f/*<S, T>*/(/*=S*/ s) => null;
main() {
  String x = f(42);
  String y = (f)(42);
}
''');
  }

  void test_genericMethods_correctlyRecognizeGenericUpperBound() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25740.
    checkFile(r'''
class Foo<T extends Pattern> {
  void method/*<U extends T>*/(dynamic/*=U*/ u) {}
}
main() {
  new Foo().method/*<String>*/("str");
  new Foo();

  new Foo<String>().method("str");
  new Foo().method("str");

  new Foo<String>().method(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/42);
}
''');
  }

  void test_genericMethods_dartMathMinMax() {
    checkFile('''
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
  printInt(/*info:DOWN_CAST_IMPLICIT*/max(1, 2.0));
  printInt(/*info:DOWN_CAST_IMPLICIT*/min(1, 2.0));
  printDouble(/*info:DOWN_CAST_IMPLICIT*/max(1, 2.0));
  printDouble(/*info:DOWN_CAST_IMPLICIT*/min(1, 2.0));

  // Types other than int and double are not accepted.
  printInt(
      /*info:DOWN_CAST_IMPLICIT*/min(
          /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hi",
          /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"there"));
}
''');
  }

  void test_genericMethods_doNotInferInvalidOverrideOfGenericMethod() {
    checkFile('''
class C {
/*=T*/ m/*<T>*/(/*=T*/ x) => x;
}
class D extends C {
/*error:INVALID_METHOD_OVERRIDE*/m(x) => x;
}
main() {
  int y = /*info:DYNAMIC_CAST*/new D()./*error:WRONG_NUMBER_OF_TYPE_ARGUMENTS*/m/*<int>*/(42);
  print(y);
}
''');
  }

  void test_genericMethods_downwardsInferenceAffectsArguments() {
    checkFile(r'''
/*=T*/ f/*<T>*/(List/*<T>*/ s) => null;
main() {
  String x = f(/*info:INFERRED_TYPE_LITERAL*/['hi']);
  String y = f(/*info:INFERRED_TYPE_LITERAL*/[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/42]);
}
''');
  }

  void test_genericMethods_downwardsInferenceFold() {
    // Regression from https://github.com/dart-lang/sdk/issues/25491
    // The first example works now, but the latter requires a full solution to
    // https://github.com/dart-lang/sdk/issues/25490
    checkFile(r'''
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

  void test_genericMethods_handleOverrideOfNonGenericWithGeneric() {
    // Regression test for crash when adding genericity
    checkFile('''
class C {
  m(x) => x;
  dynamic g(int x) => x;
}
class D extends C {
  /*=T*/ m/*<T>*/(/*=T*/ x) => x;
  /*=T*/ g/*<T>*/(/*=T*/ x) => x;
}
main() {
  int y = /*info:DYNAMIC_CAST*/(new D() as C).m(42);
  print(y);
}
  ''');
  }

  void test_genericMethods_inferGenericFunctionParameterType() {
    var mainUnit = checkFile('''
class C<T> extends D<T> {
  f/*<U>*/(x) {}
}
class D<T> {
  F/*<U>*/ f/*<U>*/(/*=U*/ u) => null;
}
typedef void F<V>(V v);
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(U) → (U) → void');
  }

  void test_genericMethods_inferGenericFunctionParameterType2() {
    var mainUnit = checkFile('''
class C<T> extends D<T> {
  f/*<U>*/(g) => null;
}
abstract class D<T> {
  void f/*<U>*/(G/*<U>*/ g);
}
typedef List<V> G<V>();
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(() → List<U>) → void');
  }

  void test_genericMethods_inferGenericFunctionReturnType() {
    var mainUnit = checkFile('''
class C<T> extends D<T> {
  f/*<U>*/(x) {}
}
class D<T> {
  F/*<U>*/ f/*<U>*/(/*=U*/ u) => null;
}
typedef V F<V>();
''');
    var f = mainUnit.getType('C').methods[0];
    expect(f.type.toString(), '<U>(U) → () → U');
  }

  void test_genericMethods_inferGenericInstantiation() {
    checkFile('''
import 'dart:math' as math;
import 'dart:math' show min;

class C {
/*=T*/ m/*<T extends num>*/(/*=T*/ x, /*=T*/ y) => null;
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

takeOOI(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeIDI(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeDID(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeOON(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);
takeOOO(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/math.max);

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

takeOOI(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeIDI(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeDID(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeOON(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);
takeOOO(/*error:STATIC_TYPE_ERROR,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/min);

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
takeOON(/*warning:DOWN_CAST_COMPOSITE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
takeOOO(/*warning:DOWN_CAST_COMPOSITE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);

// Note: this is a warning because a downcast of a method tear-off could work
// in "normal" Dart, due to bivariance.
takeOOI(/*warning:DOWN_CAST_COMPOSITE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
takeIDI(/*warning:DOWN_CAST_COMPOSITE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
takeDID(/*warning:DOWN_CAST_COMPOSITE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/new C().m);
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

  void test_genericMethods_inferGenericMethodType() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25668
    checkFile('''
class C {
  /*=T*/ m/*<T>*/(/*=T*/ x) => x;
}
class D extends C {
  m/*<S>*/(x) => x;
}
main() {
  int y = new D().m/*<int>*/(42);
  print(y);
}
  ''');
  }

  void test_genericMethods_inferJSBuiltin() {
    // TODO(jmesserly): we should change how this inference works.
    // For now this test will cover what we use.
    checkFile('''
import 'dart:_foreign_helper' show JS;
main() {
  String x = /*error:INVALID_ASSIGNMENT*/JS('int', '42');
  var y = JS('String', '"hello"');
  y = "world";
  y = /*error:INVALID_ASSIGNMENT*/42;
}
''');
  }

  void test_genericMethods_IterableAndFuture() {
    checkFile('''
import 'dart:async';

Future<int> make(int x) => (/*info:INFERRED_TYPE_ALLOCATION*/new Future(() => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(list);
  Future<String> results2 = results.then((List<int> list)
    => list.fold('', /*info:INFERRED_TYPE_CLOSURE*/(x, y) => x + y.toString()));
}
''');
  }

  void test_genericMethods_usesGreatestLowerBound() {
    var mainUnit = checkFile(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

/*=T*/ generic/*<T>*/(a(/*=T*/ _), b(/*=T*/ _)) => null;

var v = generic((F f) => null, (G g) => null);
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(num) → List<int>');
  }

  void test_infer_assignToIndex() {
    checkFile(r'''
List<double> a = <double>[];
var b = (a[0] = 1.0);
''');
  }

  void test_infer_assignToProperty() {
    checkFile(r'''
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

  void test_infer_assignToProperty_custom() {
    checkFile(r'''
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

  void test_infer_assignToRef() {
    checkFile(r'''
class A {
  int f;
}
A a = new A();
var b = (a.f = 1);
var c = 0;
var d = (c = 1);
''');
  }

  void test_infer_binary_custom() {
    checkFile(r'''
class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}
var v_add = new A() + 'foo';
var v_minus = new A() - 'bar';
''');
  }

  void test_infer_binary_doubleDouble() {
    checkFile(r'''
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

  void test_infer_binary_doubleInt() {
    checkFile(r'''
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

  void test_infer_binary_intDouble() {
    checkFile(r'''
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

  void test_infer_binary_intInt() {
    checkFile(r'''
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

  void test_infer_conditional() {
    checkFile(r'''
var a = 1 == 2 ? 1 : 2.0;
var b = 1 == 2 ? 1.0 : 2;
''');
  }

  void test_infer_prefixExpression() {
    checkFile(r'''
var a_not = !true;
var a_complement = ~1;
var a_negate = -1;
''');
  }

  void test_infer_prefixExpression_custom() {
    checkFile(r'''
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

  void test_infer_throw() {
    checkFile(r'''
var t = true;
var a = (throw 0);
var b = (throw 0) ? 1 : 2;
var c = t ? (throw 1) : 2;
var d = t ? 1 : (throw 2);
''');
  }

  void test_infer_typeCast() {
    checkFile(r'''
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

  void test_infer_typedListLiteral() {
    checkFile(r'''
var a = <int>[];
var b = <double>[1.0, 2.0, 3.0];
var c = <List<int>>[];
var d = <dynamic>[1, 2.0, false];
''');
  }

  void test_infer_typedMapLiteral() {
    checkFile(r'''
var a = <int, String>{0: 'aaa', 1: 'bbb'};
var b = <double, int>{1.1: 1, 2.2: 2};
var c = <List<int>, Map<String, double>>{};
var d = <int, dynamic>{};
var e = <dynamic, int>{};
var f = <dynamic, dynamic>{};
''');
  }

  void test_infer_use_of_void() {
    checkFile('''
class B {
  void f() {}
}
class C extends B {
  f() {}
}
var x = new C()./*info:USE_OF_VOID_RESULT*/f();
''');
  }

  void test_inferConstsTransitively() {
    addFile(
        '''
const b1 = 2;
''',
        name: '/b.dart');
    addFile(
        '''
import 'main.dart';
import 'b.dart';
const a1 = m2;
const a2 = b1;
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
const m1 = a1;
const m2 = a2;

foo() {
  int i;
  i = m1;
}
''');
  }

  void test_inferCorrectlyOnMultipleVariablesDeclaredTogether() {
    checkFile('''
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

  void test_inferedType_usesSyntheticFunctionType() {
    var mainUnit = checkFile('''
int f() => null;
String g() => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<() → Object>');
  }

  void test_inferedType_usesSyntheticFunctionType_functionTypedParam() {
    var mainUnit = checkFile('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<((String) → int) → Object>');
  }

  void test_inferedType_usesSyntheticFunctionType_namedParam() {
    var mainUnit = checkFile('''
int f({int x}) => null;
String g({int x}) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<({x: int}) → Object>');
  }

  void test_inferedType_usesSyntheticFunctionType_positionalParam() {
    var mainUnit = checkFile('''
int f([int x]) => null;
String g([int x]) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<([int]) → Object>');
  }

  void test_inferedType_usesSyntheticFunctionType_requiredParam() {
    var mainUnit = checkFile('''
int f(int x) => null;
String g(int x) => null;
var v = /*info:INFERRED_TYPE_LITERAL*/[f, g];
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'List<(int) → Object>');
  }

  void test_inferenceInCyclesIsDeterministic() {
    addFile(
        '''
import 'b.dart';
class A {
  static final a1 = B.b1;
  final a2 = new B().b2;
}
''',
        name: '/a.dart');
    addFile(
        '''
class B {
  static final b1 = 1;
  final b2 = 1;
}
''',
        name: '/b.dart');
    addFile(
        '''
import "main.dart"; // creates a cycle

class C {
  static final c1 = 1;
  final c2 = 1;
}
''',
        name: '/c.dart');
    addFile(
        '''
library e;
import 'a.dart';
part 'e2.dart';

class E {
  static final e1 = 1;
  static final e2 = F.f1;
  static final e3 = A.a1;
  final e4 = 1;
  final e5 = new F().f2;
  final e6 = new A().a2;
}
''',
        name: '/e.dart');
    addFile(
        '''
part 'f2.dart';
''',
        name: '/f.dart');
    addFile(
        '''
part of e;
class F {
  static final f1 = 1;
  final f2 = 1;
}
''',
        name: '/e2.dart');
    checkFile('''
import "a.dart";
import "c.dart";
import "e.dart";

class D {
  static final d1 = A.a1 + 1;
  static final d2 = C.c1 + 1;
  final d3 = new A().a2;
  final d4 = new C().c2;
}

test1() {
  int x = 0;
  // inference in A works, it's not in a cycle
  x = A.a1;
  x = new A().a2;

  // Within a cycle we allow inference when the RHS is well known, but
  // not when it depends on other fields within the cycle
  x = C.c1;
  x = D.d1;
  x = D.d2;
  x = new C().c2;
  x = new D().d3;
  x = /*info:DYNAMIC_CAST*/new D().d4;


  // Similarly if the library contains parts.
  x = E.e1;
  x = E.e2;
  x = E.e3;
  x = new E().e4;
  x = /*info:DYNAMIC_CAST*/new E().e5;
  x = new E().e6;
  x = F.f1;
  x = new F().f2;
}
''');
  }

  void test_inferFromComplexExpressionsIfOuterMostValueIsPrecise() {
    checkFile('''
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
                        // conected component.
var g = -3;
var h = new A() + 3;
var i = /*error:UNDEFINED_OPERATOR*/- new A();
var j = null as B;

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

  void test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields() {
    checkFile('''
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

  void test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() {
    checkFile('''
class A {
  final x = null;
}

class B implements A {
  final x = 2;
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/new B().x;
  int z = new B().x;
}
''');
  }

  void test_inferFromVariablesInCycleLibsWhenFlagIsOn() {
    addFile(
        '''
import 'main.dart';
var x = 2; // ok to infer
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
var y = x; // now ok :)

test1() {
  int t = 3;
  t = x;
  t = y;
}
''');
  }

  void test_inferFromVariablesInCycleLibsWhenFlagIsOn2() {
    addFile(
        '''
import 'main.dart';
class A { static var x = 2; }
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  int t = 3;
  t = A.x;
  t = B.y;
}
''');
  }

  void test_inferFromVariablesInNonCycleImportsWithFlag() {
    addFile(
        '''
var x = 2;
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
var y = x;

test1() {
  x = /*error:INVALID_ASSIGNMENT*/"hi";
  y = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  void test_inferFromVariablesInNonCycleImportsWithFlag2() {
    addFile(
        '''
class A { static var x = 2; }
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  A.x = /*error:INVALID_ASSIGNMENT*/"hi";
  B.y = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  void test_inferGenericMethodType_named() {
    var unit = checkFile('''
class C {
  /*=T*/ m/*<T>*/(int a, {String b, /*=T*/ c}) => null;
}
var y = new C().m(1, b: 'bbb', c: 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'double');
  }

  void test_inferGenericMethodType_positional() {
    var unit = checkFile('''
class C {
  /*=T*/ m/*<T>*/(int a, [/*=T*/ b]) => null;
}
var y = new C().m(1, 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'double');
  }

  void test_inferGenericMethodType_positional2() {
    var unit = checkFile('''
class C {
  /*=T*/ m/*<T>*/(int a, [String b, /*=T*/ c]) => null;
}
var y = new C().m(1, 'bbb', 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'double');
  }

  void test_inferGenericMethodType_required() {
    var unit = checkFile('''
class C {
  /*=T*/ m/*<T>*/(/*=T*/ x) => x;
}
var y = new C().m(42);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  void test_inferIfComplexExpressionsReadPossibleInferredField() {
    // but flags can enable this behavior.
    addFile(
        '''
class A {
  var x = 3;
}
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
class B {
  var y = 3;
}
final t1 = new A();
final t2 = new A().x;
final t3 = new B();
final t4 = new B().y;

test1() {
  int i = 0;
  A a;
  B b;
  a = t1;
  i = t2;
  b = t3;
  i = /*info:DYNAMIC_CAST*/t4;
  i = new B().y; // B.y was inferred though
}
''');
  }

  void test_inferListLiteralNestedInMapLiteral() {
    checkFile(r'''
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

  void test_inferred_nonstatic_field_depends_on_static_field_complex() {
    var mainUnit = checkFile('''
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

  void test_inferred_nonstatic_field_depends_on_toplevel_var_simple() {
    var mainUnit = checkFile('''
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

  void test_inferredInitializingFormalChecksDefaultValue() {
    checkFile('''
class Foo {
  var x = 1;
  Foo([this.x = /*error:INVALID_ASSIGNMENT*/"1"]);
}''');
  }

  void test_inferredType_blockBodiedClosure_noArguments() {
    var mainUnit = checkFile('''
class C {
  static final v = () {};
}
''');
    var v = mainUnit.getType('C').fields[0];
    expect(v.type.toString(), '() → dynamic');
  }

  void test_inferredType_blockClosure_noArgs_noReturn() {
    var mainUnit = checkFile('''
var f = () {};
''');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '() → dynamic');
  }

  void test_inferredType_customBinaryOp() {
    var mainUnit = checkFile('''
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

  void test_inferredType_customBinaryOp_viaInterface() {
    var mainUnit = checkFile('''
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

  void test_inferredType_customIndexOp() {
    var mainUnit = checkFile('''
class C {
  bool operator[](int index) => true;
}
C c;
var x = c[0];
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_customIndexOp_viaInterface() {
    var mainUnit = checkFile('''
class I {
  bool operator[](int index) => true;
}
abstract class C implements I {}
C c;
var x = c[0];
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_customUnaryOp() {
    var mainUnit = checkFile('''
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

  void test_inferredType_customUnaryOp_viaInterface() {
    var mainUnit = checkFile('''
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

  void test_inferredType_extractMethodTearOff() {
    var mainUnit = checkFile('''
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

  void test_inferredType_extractMethodTearOff_viaInterface() {
    var mainUnit = checkFile('''
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

  void test_inferredType_extractProperty() {
    var mainUnit = checkFile('''
class C {
  bool b;
}
C f() => null;
var x = f().b;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_extractProperty_prefixedIdentifier() {
    var mainUnit = checkFile('''
class C {
  bool b;
}
C c;
var x = c.b;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_extractProperty_prefixedIdentifier_viaInterface() {
    var mainUnit = checkFile('''
class I {
  bool b;
}
abstract class C implements I {}
C c;
var x = c.b;
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_extractProperty_viaInterface() {
    var mainUnit = checkFile('''
class I {
  bool b;
}
abstract class C implements I {}
C f() => null;
var x = f().b;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'bool');
  }

  void test_inferredType_fromTopLevelExecutableTearoff() {
    var mainUnit = checkFile('''
var v = print;
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(Object) → void');
  }

  void test_inferredType_invokeMethod() {
    var mainUnit = checkFile('''
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

  void test_inferredType_invokeMethod_viaInterface() {
    var mainUnit = checkFile('''
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

  void test_inferredType_isEnum() {
    var mainUnit = checkFile('''
enum E { v1 }
final x = E.v1;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'E');
  }

  void test_inferredType_isEnumValues() {
    var mainUnit = checkFile('''
enum E { v1 }
final x = E.values;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'List<E>');
  }

  void test_inferredType_isTypedef() {
    var mainUnit = checkFile('''
typedef void F();
final x = <String, F>{};
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<String, () → void>');
  }

  void test_inferredType_isTypedef_parameterized() {
    var mainUnit = checkFile('''
typedef T F<T>();
final x = <String, F<int>>{};
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<String, () → int>');
  }

  void test_inferredType_opAssignToProperty() {
    var mainUnit = checkFile('''
class C {
  num n;
}
C f() => null;
var x = (f().n *= null);
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'num');
  }

  void test_inferredType_opAssignToProperty_prefixedIdentifier() {
    var mainUnit = checkFile('''
class C {
  num n;
}
C c;
var x = (c.n *= null);
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'num');
  }

  void test_inferredType_opAssignToProperty_prefixedIdentifier_viaInterface() {
    var mainUnit = checkFile('''
class I {
  num n;
}
abstract class C implements I {}
C c;
var x = (c.n *= null);
''');
    var x = mainUnit.topLevelVariables[1];
    expect(x.name, 'x');
    expect(x.type.toString(), 'num');
  }

  void test_inferredType_opAssignToProperty_viaInterface() {
    var mainUnit = checkFile('''
class I {
  num n;
}
abstract class C implements I {}
C f() => null;
var x = (f().n *= null);
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.name, 'x');
    expect(x.type.toString(), 'num');
  }

  void test_inferredType_viaClosure_multipleLevelsOfNesting() {
    var mainUnit = checkFile('''
class C {
  static final f = (bool b) => (int i) => /*info:INFERRED_TYPE_LITERAL*/{i: b};
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → (int) → Map<int, bool>');
  }

  void test_inferredType_viaClosure_typeDependsOnArgs() {
    var mainUnit = checkFile('''
class C {
  static final f = (bool b) => b;
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → bool');
  }

  void test_inferredType_viaClosure_typeIndependentOfArgs_field() {
    var mainUnit = checkFile('''
class C {
  static final f = (bool b) => 1;
}
''');
    var f = mainUnit.getType('C').fields[0];
    expect(f.type.toString(), '(bool) → int');
  }

  void test_inferredType_viaClosure_typeIndependentOfArgs_topLevel() {
    var mainUnit = checkFile('final f = (bool b) => 1;');
    var f = mainUnit.topLevelVariables[0];
    expect(f.type.toString(), '(bool) → int');
  }

  void test_inferStaticsTransitively() {
    addFile(
        '''
final b1 = 2;
''',
        name: '/b.dart');
    addFile(
        '''
import 'main.dart';
import 'b.dart';
final a1 = m2;
class A {
  static final a2 = b1;
}
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
final m1 = a1;
final m2 = A.a2;

foo() {
  int i;
  i = m1;
}
''');
  }

  void test_inferStaticsTransitively2() {
    checkFile('''
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

  void test_inferStaticsTransitively3() {
    addFile(
        '''
const a1 = 3;
const a2 = 4;
class A {
  static const a3 = null;
}
''',
        name: '/a.dart');
    checkFile('''
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

  void test_inferStaticsWithMethodInvocations() {
    addFile(
        '''
m3(String a, String b, [a1,a2]) {}
''',
        name: '/a.dart');
    checkFile('''
import 'a.dart';
class T {
  static final T foo = m1(m2(m3('', '')));
  static T m1(String m) { return null; }
  static String m2(e) { return ''; }
}
''');
  }

  void test_inferTypeOnOverriddenFields2() {
    checkFile('''
class A {
  int x = 2;
}

class B extends A {
  /*error:INVALID_FIELD_OVERRIDE*/get x => 3;
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/new B().x;
  int z = new B().x;
}
''');
  }

  void test_inferTypeOnOverriddenFields4() {
    checkFile('''
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

  void test_inferTypeOnVar() {
    // Error also expected when declared type is `int`.
    checkFile('''
test1() {
  int x = 3;
  x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  void test_inferTypeOnVar2() {
    checkFile('''
test2() {
  var x = 3;
  x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  void test_inferTypeOnVarFromField() {
    checkFile('''
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

  void test_inferTypeOnVarFromTopLevel() {
    checkFile('''
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

  void test_inferTypeRegardlessOfDeclarationOrderOrCycles() {
    addFile(
        '''
import 'main.dart';

class B extends A { }
''',
        name: '/b.dart');
    checkFile('''
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

  void test_inferTypesOnGenericInstantiations_3() {
    checkFile('''
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

  void test_inferTypesOnGenericInstantiations_4() {
    checkFile('''
class A<T> {
  T x;
}

class B<E> extends A<E> {
  E y;
  /*error:INVALID_FIELD_OVERRIDE*/get x => y;
}

foo() {
  int y = /*error:INVALID_ASSIGNMENT*/new B<String>().x;
  String z = new B<String>().x;
}
''');
  }

  void test_inferTypesOnGenericInstantiations_5() {
    checkFile('''
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

  void test_inferTypesOnGenericInstantiations_infer() {
    checkFile('''
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

  void test_inferTypesOnGenericInstantiationsInLibraryCycle() {
    // Note: this is a regression test for a non-deterministic behavior we used to
    // have with inference in library cycles. If you see this test flake out,
    // change `test` to `skip_test` and reopen bug #48.
    addFile(
        '''
import 'main.dart';
abstract class I<E> {
  A<E> m(a, String f(v, int e));
}
''',
        name: '/a.dart');
    checkFile('''
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

  void test_inferTypesOnLoopIndices_forEachLoop() {
    checkFile('''
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
    // The INVALID_ASSIGNMENT hint is because type propagation knows x is
    // a Foo.
    String y = /*info:DYNAMIC_CAST,info:INVALID_ASSIGNMENT*/x;
  }

  for (String x in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/list) {
    String y = x;
  }

  var z;
  for(z in list) {
    String y = /*info:DYNAMIC_CAST,info:INVALID_ASSIGNMENT*/z;
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

  void test_inferTypesOnLoopIndices_forLoopWithInference() {
    checkFile('''
test() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
  }
}
''');
  }

  void test_instanceField_basedOnInstanceField_betweenCycles() {
    // Verify that all instance fields in one library cycle are inferred before
    // an instance fields in a dependent library cycle.
    addFile(
        '''
import 'b.dart';
class A {
  var x = new B().y;
  var y = 0;
}
''',
        name: '/a.dart');
    addFile(
        '''
class B {
  var x = new B().y;
  var y = 0;
}
''',
        name: '/b.dart');
    checkFile('''
import 'a.dart';
import 'b.dart';
main() {
  new A().x = /*error:INVALID_ASSIGNMENT*/'foo';
  new B().x = 'foo';
}
''');
  }

  void test_instanceField_basedOnInstanceField_withinCycle() {
    // Verify that all instance field inferences that occur within the same
    // library cycle happen as though they occurred "all at once", so no
    // instance field in the library cycle can inherit its type from another
    // instance field in the same library cycle.
    addFile(
        '''
import 'b.dart';
class A {
  var x = new B().y;
  var y = 0;
}
''',
        name: '/a.dart');
    addFile(
        '''
import 'a.dart';
class B {
  var x = new A().y;
  var y = 0;
}
''',
        name: '/b.dart');
    checkFile('''
import 'a.dart';
import 'b.dart';
main() {
  new A().x = 'foo';
  new B().x = 'foo';
}
''');
  }

  void test_instantiateToBounds_generic2_hasBound_definedAfter() {
    var unit = checkFile(r'''
class B<T extends A> {}
class A<T extends int> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  void test_instantiateToBounds_generic2_hasBound_definedBefore() {
    var unit = checkFile(r'''
class A<T extends int> {}
class B<T extends A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  void test_instantiateToBounds_generic2_noBound() {
    var unit = checkFile(r'''
class A<T> {}
class B<T extends A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A<dynamic>>');
  }

  void test_instantiateToBounds_generic_hasBound_definedAfter() {
    var unit = checkFile(r'''
A v = null;
class A<T extends int> {}
''');
    expect(unit.topLevelVariables[0].type.toString(), 'A<int>');
  }

  void test_instantiateToBounds_generic_hasBound_definedBefore() {
    var unit = checkFile(r'''
class A<T extends int> {}
A v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'A<int>');
  }

  void test_instantiateToBounds_invokeConstructor_noBound() {
    var unit = checkFile('''
class C<T> {}
var x = new C();
''');
    expect(unit.topLevelVariables[0].type.toString(), 'C<dynamic>');
  }

  void test_instantiateToBounds_invokeConstructor_typeArgsExact() {
    var unit = checkFile('''
class C<T extends num> {}
var x = new C<int>();
''');
    expect(unit.topLevelVariables[0].type.toString(), 'C<int>');
  }

  void test_instantiateToBounds_notGeneric() {
    var unit = checkFile(r'''
class A {}
class B<T extends A> {}
B v = null;
''');
    expect(unit.topLevelVariables[0].type.toString(), 'B<A>');
  }

  void test_listLiterals() {
    checkFile(r'''
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

  void test_listLiterals_topLevel() {
    checkFile(r'''
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

  void test_listLiteralsShouldNotInferBottom() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = checkFile(r'''
test1() {
  var x = [null];
  x.add(42);
}
''');
    var x = unit.functions[0].localVariables[0];
    expect(x.type.toString(), 'List<dynamic>');
  }

  void test_listLiteralsShouldNotInferBottom_topLevel() {
    var unit = checkFile(r'''
var x = [null];
''');
    var x = unit.topLevelVariables[0];
    expect(x.type.toString(), 'List<dynamic>');
  }

  void test_mapLiterals() {
    checkFile(r'''
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

  void test_mapLiterals_topLevel() {
    checkFile(r'''
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

  void test_mapLiteralsShouldNotInferBottom() {
    if (!mayCheckTypesOfLocals) {
      return;
    }
    var unit = checkFile(r'''
test1() {
  var x = { null: null };
  x[3] = 'z';
}
''');
    var x = unit.functions[0].localVariables[0];
    expect(x.type.toString(), 'Map<dynamic, dynamic>');
  }

  void test_mapLiteralsShouldNotInferBottom_topLevel() {
    var unit = checkFile(r'''
var x = { null: null };
''');
    var x = unit.topLevelVariables[0];
    expect(x.type.toString(), 'Map<dynamic, dynamic>');
  }

  void test_methodCall_withTypeArguments_instanceMethod() {
    var mainUnit = checkFile('''
class C {
  D/*<T>*/ f/*<T>*/() => null;
}
class D<T> {}
var f = new C().f/*<int>*/();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  void test_methodCall_withTypeArguments_instanceMethod_identifierSequence() {
    var mainUnit = checkFile('''
class C {
  D/*<T>*/ f/*<T>*/() => null;
}
class D<T> {}
C c;
var f = c.f/*<int>*/();
''');
    var v = mainUnit.topLevelVariables[1];
    expect(v.name, 'f');
    expect(v.type.toString(), 'D<int>');
  }

  void test_methodCall_withTypeArguments_staticMethod() {
    var mainUnit = checkFile('''
class C {
  static D/*<T>*/ f/*<T>*/() => null;
}
class D<T> {}
var f = C.f/*<int>*/();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  void test_methodCall_withTypeArguments_topLevelFunction() {
    var mainUnit = checkFile('''
D/*<T>*/ f/*<T>*/() => null;
class D<T> {}
var g = f/*<int>*/();
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), 'D<int>');
  }

  void test_noErrorWhenDeclaredTypeIsNumAndAssignedNull() {
    checkFile('''
test1() {
  num x = 3;
  x = null;
}
''');
  }

  void test_nullLiteralShouldNotInferAsBottom() {
    // Regression test for https://github.com/dart-lang/dev_compiler/issues/47
    checkFile(r'''
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

  void test_propagateInferenceToFieldInClass() {
    checkFile('''
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

  void test_propagateInferenceToFieldInClassDynamicWarnings() {
    checkFile('''
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

  void test_propagateInferenceTransitively() {
    checkFile('''
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

  void test_propagateInferenceTransitively2() {
    checkFile('''
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

  void test_referenceToFieldOfStaticField() {
    var mainUnit = checkFile('''
class C {
  static D d;
}
class D {
  int i;
}
final x = C.d.i;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'int');
  }

  void test_referenceToFieldOfStaticGetter() {
    var mainUnit = checkFile('''
class C {
  static D get d => null;
}
class D {
  int i;
}
final x = C.d.i;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'int');
  }

  void test_referenceToTypedef() {
    var mainUnit = checkFile('''
typedef void F();
final x = F;
''');
    var x = mainUnit.topLevelVariables[0];
    expect(x.type.toString(), 'Type');
  }

  void test_refineBinaryExpressionType_typeParameter_T_double() {
    checkFile('''
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

  void test_refineBinaryExpressionType_typeParameter_T_int() {
    checkFile('''
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

  void test_refineBinaryExpressionType_typeParameter_T_T() {
    checkFile('''
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

  void test_staticMethod_tearoff() {
    var mainUnit = checkFile('''
const v = C.f;
class C {
  static int f(String s) => null;
}
''');
    var v = mainUnit.topLevelVariables[0];
    expect(v.type.toString(), '(String) → int');
  }

  void test_staticRefersToNonStaticField_inOtherLibraryCycle() {
    addFile(
        '''
import 'b.dart';
var x = new C().f;
''',
        name: '/a.dart');
    addFile(
        '''
class C {
  var f = 0;
}
''',
        name: '/b.dart');
    checkFile('''
import 'a.dart';
test() {
  x = /*error:INVALID_ASSIGNMENT*/"hi";
}
''');
  }

  void test_staticRefersToNonstaticField_inSameLibraryCycle() {
    addFile(
        '''
import 'b.dart';
var x = new C().f;
class D {
  var f = 0;
}
''',
        name: '/a.dart');
    addFile(
        '''
import 'a.dart';
var y = new D().f;
class C {
  var f = 0;
}
''',
        name: '/b.dart');
    checkFile('''
import 'a.dart';
import 'b.dart';
test() {
  x = "hi";
  y = "hi";
}
''');
  }

  void test_typeInferenceDependency_staticVariable_inIdentifierSequence() {
    // Check that type inference dependencies are properly checked when a static
    // variable appears in the middle of a string of identifiers separated by
    // '.'.
    var mainUnit = checkFile('''
final a = /*info:DYNAMIC_INVOKE*/C.d.i;
class C {
  static final d = new D(a);
}
class D {
  D(_);
  int i;
}
''');
    // No type should be inferred for a because there is a circular reference
    // between a and C.d.
    var a = mainUnit.topLevelVariables[0];
    expect(a.type.toString(), 'dynamic');
  }

  void test_typeInferenceDependency_topLevelVariable_inIdentifierSequence() {
    // Check that type inference dependencies are properly checked when a top
    // level variable appears at the beginning of a string of identifiers
    // separated by '.'.
    checkFile('''
final a = /*info:DYNAMIC_INVOKE*/c.i;
final c = new C(a);
class C {
  C(_);
  int i;
}
''');
    // No type should be inferred for a because there is a circular reference
    // between a and c.
  }
}

@reflectiveTest
class InferredTypeTest extends InferredTypeMixin {
  @override
  bool get mayCheckTypesOfLocals => true;

  /// Adds a file to check. The file should contain:
  ///
  ///   * all expected failures are listed in the source code using comments
  ///     immediately in front of the AST node that should contain the error.
  ///
  ///   * errors are formatted as a token `severity:ErrorCode`, where
  ///     `severity` is the ErrorSeverity the error would be reported at, and
  ///     `ErrorCode` is the error code's name.
  ///
  /// For example to check that an assignment produces a type error, you can
  /// create a file like:
  ///
  ///     addFile('''
  ///       String x = /*error:STATIC_TYPE_ERROR*/3;
  ///     ''');
  ///     check();
  ///
  /// For a single file, you may also use [checkFile].
  @override
  void addFile(String content, {String name: '/main.dart'}) {
    helper.addFile(content, name: name);
  }

  /// Adds a file using [helper.addFile] and calls [helper.check].
  ///
  /// Also returns the resolved compilation unit.
  @override
  CompilationUnitElement checkFile(String content) {
    return helper.checkFile(content).element;
  }
}
