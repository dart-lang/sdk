// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_lambdas`



/* TODO: Uncomment this test when parser accepts generics
Function stateList<T>(int finder) {
  return (int element) => _stateOf<T>(element, finder); // OK
}

_stateOf<T>(int a, int b) {

}
*/

class MyClass {
  int m1() {
    return 0;
  }

  int m2(int p) {
    return p;
  }
}

void main() {
  List<String> names = [];

  final array = <MyClass>[];
  final x = new MyClass();

  // ignore: unused_local_variable
  final notRelevantQuestionPeriod = (p) => array[x?.m1()].m2(p); // LINT

  names.forEach((name) { // LINT
    print(name);
  });

  names.forEach(print); // OK

  names.where((e) => names.contains(e)); // LINT
  names.where((e) => names?.contains(e)); // OK
  // ignore: unused_local_variable
  var a = (() => names.removeLast()); // LINT
  // ignore: unused_local_variable
  var b = (() => names?.removeLast()); // OK

  names.where((e) => e.contains(e)); // OK

  // ignore: undefined_getter
  names.where((e) => e.a.contains(e)); // OK

  names.where((e) => // OK
      ((a) => e.contains(a))(e)); // LINT

  names.where((e) => // OK
      ((a) => e?.contains(a))(e)); // OK

  var noStatementLambda = () { // OK
    // Empty lambda
  };

  names.forEach((name) { // OK
    noStatementLambda(); // More than one statement
    print(name);
  });

  // ignore: unused_local_variable
  var deeplyNestedVariable = (a, b) { // OK
    foo(foo(b)).foo(a, b);
  };
}

foo(a) {}

void method() {
  List<List> names = [];
  names.add(names);

  // ignore: unused_local_variable
  var a = names.where((e) => ((e) => e.contains(e))(e)); // LINT
  // ignore: unused_local_variable
  var b = names.where((e) => // LINT
      ((e) => e?.contains(e))(e));
  // Can be replaced by names.where((e) => e?.contains(e));

  // ignore: unused_local_variable
  var c = names.where((e) { // LINT
    return ((e) {
      return e.contains(e);
    })(e);
  });
}
