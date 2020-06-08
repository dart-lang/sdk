// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_lambdas`

// ignore_for_file: always_declare_return_types
// ignore_for_file: omit_local_variable_types
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: unused_local_variable

int count(String s) => s.length;
final strings = ['a', 'bb', 'ccc', 'dddd'];

// ignore: avoid_annotating_with_dynamic
typedef F = int Function(dynamic s);

F f  = (s) => count(s); //OK

final map = Map<String, int>.fromIterable(strings, value: (s) => count(s)); //OK

Function stateList<T>(int finder) {
  return (int element) => _stateOf<T>(element, finder); // OK
}

_stateOf<T>(int a, int b) {

}

class GettersTest {
  final a = 1;
  get b => 2;
  get c => a;
  Function finalVar() {
    return () { // LINT
      a.toString();
    };
  }
  Function getter1() {
    return () { // OK
      b.toString();
    };
  }
  Function getter2() {
    return () { // OK
      c.toString();
    };
  }
}

class MyClass {
  final m1 = 0;

  int m2(int p) {
    return p;
  }
}

void main() {

  final List<String> finalList = [];
  List<String> nonFinalList = [];

  final array = <MyClass>[];
  final x = MyClass();

  final notRelevantQuestionPeriod = (p) => array[x?.m1].m2(p); // OK
  final correctNotRelevantQuestionPeriod = array[x?.m1].m2; // OK

  finalList.forEach((name) { // LINT
    print(name);
  });
  finalList.forEach(print); // OK

  // Lambdas as parameters.
  finalList.where((e) => finalList.contains(e)); // LINT
  finalList.where((e) => nonFinalList.contains(e)); // OK
  finalList.where((e) => finalList?.contains(e)); // OK
  finalList.where(finalList.contains); // OK

  // Lambdas assigned to variables.
  var a = (() => finalList.removeLast()); // LINT
  var b = (() => nonFinalList.removeLast()); // OK
  var c = (() => finalList?.removeLast()); // OK
  var d = finalList.removeLast; // OK

  var asyncLambda = (() async => finalList.removeLast()); // OK

  finalList.where((e) => e.contains(e)); // OK

  // ignore: undefined_getter
  finalList.where((e) => e.a.contains(e)); // OK

  // Linted because parameter is final.
  finalList.where((final e) =>
      ((a) => e.contains(a))(e)); // LINT
  finalList.where((final e) =>
      (e.contains)(e)); // OK
  finalList.where((e) =>
      ((a) => e.contains(a))(e)); // OK

  finalList.where((e) => // OK
      ((a) => e?.contains(a))(e)); // OK

  var noStatementLambda = () { // OK
    // Empty lambda
  };

  finalList.forEach((name) { // OK
    print(name); // More than one statement
    print(name); // More than one statement
  });

  var deeplyNestedVariable = (a, b) { // OK
    foo(foo(b)).foo(a, b);
  };
}

foo(a) {}

void method() {
  List<List> names = [];
  names.add(names);

  var a = names.where((e) => ((e) => e.contains(e))(e)); // LINT
  var b = names.where((e) => // LINT
      ((e) => e?.contains(e))(e));
  names.where((e) => e?.contains(e)); // OK

  var c = names.where((e) { // LINT
    return ((e) {
      return e.contains(e);
    })(e);
  });
}

void reportedFalsePositive() {
  Function makeCallable(void f()) => f;

  var f = () => print('a');

  // r1 was linted (r2 is the result to remove the lint)
  var r1 = makeCallable((){ // OK
    f();
  });
  var r2 = makeCallable(f); // OK

  f = () => print('b');

  r1(); // prints b
  r2(); // prints a

  // a lambda must be used to specify generics
  void genFun<T>() => null;
  Function aGenFun = () => genFun<int>(); // OK
}

void reportedTruePositive () {
  final f = (){ };
  final lambda = () { f(); }; // LINT
  final equivalent = f; // OK
}
