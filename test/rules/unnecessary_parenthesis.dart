// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_parenthesis`

import 'dart:async';

var a, b, c, d;

main() async {
  1; // OK
  (1); // LINT
  print(1); // OK
  print((1)); // LINT
  if (a && b || c && d) true; // OK
  // OK because it may be hard to know all of the precedence rules.
  if ((a && b) || c && d) true; // OK
  (await new Future.value(1)).toString(); // OK
  ('' as String).toString(); // OK
  !(true as bool); // OK
  a = (a); // LINT
  (a) ? true : false; // LINT
  true ? (a) : false; // LINT
  true ? true : (a); // LINT
  // OK because it is unobvious that the space-involving ternary binds tighter
  // than the cascade.
  (true ? [] : [])..add(''); // OK
  (a ?? true) ? true : true; // OK
  true ? [] : []
    ..add(''); // OK
  m(p: (1 + 3)); // LINT

  // OK because it is unobvious where cascades fall in precedence.
  a..b = (c..d); // OK
  a.b = (c..d); // OK
  a..b = (c.d); // OK
  ((x) => x is bool ? x : false)(a); // OK
  (fn)(a); // LINT

  // OK because unary operators mixed with space-separated tokens may have
  // unexpected ordering.
  !(const [7].contains(42)); // OK
  !(new List(3).contains(42)); // OK
  !(await Future.value(false)); // OK
  -(new List(3).length); // OK
  !(new List(3).length.isEven); // OK
  -(new List(3).length.abs().abs().abs()); // OK
  -(new List(3).length.sign.sign.sign); // OK
  !(const [7]).contains(42); // OK

  // OK because some methods are defined on Type, but removing the parentheses
  // would attempt to call a _static_ method on the target.
  (String).hashCode;
  (int).runtimeType;
  (bool).noSuchMethod();
  (double).toString();

  ({false: 'false', true: 'true'}).forEach((k, v) => print('$k: $v'));
  ({false, true}).forEach(print);
  ({false, true}).length;
  print(({1, 2, 3}).length); // LINT
  ([false, true]).forEach(print); // LINT
}

m({p}) => null;

bool Function(dynamic) get fn => (x) => x is bool ? x : false;

class ClassWithFunction {
  Function f;
  int number;

  ClassWithFunction.named(int a) : this.number = (a + 2); // LINT
  // https://github.com/dart-lang/linter/issues/1473
  ClassWithFunction.named2(Function value) : this.f = (value ?? (_) => 42); // OK
}

class ClassWithClassWithFunction {
  ClassWithFunction c;

  // https://github.com/dart-lang/linter/issues/1395
  ClassWithClassWithFunction() : c = (ClassWithFunction()..f = () => 42); // OK
}

class UnnecessaryParenthesis {
  ClassWithClassWithFunction c;

  UnnecessaryParenthesis()
      : c = (ClassWithClassWithFunction()
          ..c = ClassWithFunction().f = () => 42); // OK
}
