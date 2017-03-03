// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_lambdas`

void main() {
  List<String> names = [];

  names.forEach((name) { // LINT
    print(name);
  });

  names.forEach(print); // OK

  names.where((e) => names.contains(e)); // LINT
  // ignore: unused_local_variable
  var a = (() => names.removeLast()); // LINT

  names.where((e) => e.contains(e)); // OK

  // ignore: undefined_getter
  names.where((e) => e.a.contains(e)); // OK

  names.where((e) => // OK
      ((a) => e.contains(a))(e)); // LINT

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

foo(a) {

}

void method() {
  List<List> names = [];
  names.add(names);
  var a = names.where((e) => ((e) => e.contains(e))(e)); // LINT
  var b = names.where((e) { // LINT
    return ((e) {
      return e.contains(e);
    })(e);
  });
  print(a.length);
  print(b.length);
}
