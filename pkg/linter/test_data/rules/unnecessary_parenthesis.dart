// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  (b - a) as num; // OK
  (b - a) is num; // OK
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

  // OK because it is unobvious where cascades fall in precedence.
  a..b = (c..d); // OK
  a.b = (c..d); // OK
  a..b = (c.d); // OK
  ((x) => x is bool ? x : false)(a); // OK
  (fn)(a); // LINT

  // OK because unary operators mixed with space-separated tokens may have
  // unexpected ordering.
  !(const [7].contains(42)); // OK
  !(new List.empty().contains(42)); // OK
  !(await Future.value(false)); // OK
  -(new List.empty().length); // OK
  !(new List.empty().length.isEven); // OK
  -(new List.empty().length.abs().abs().abs()); // OK
  -(new List.empty().length.sign.sign.sign); // OK
  !(const [7]).contains(42); // OK

  // OK because some methods are defined on Type, but removing the parentheses
  // would attempt to call a _static_ method on the target.
  (String).hashCode;
  (int).runtimeType;
  (bool).noSuchMethod(invocation()!);
  (double).toString();

  ({false: 'false', true: 'true'}).forEach((k, v) => print('$k: $v'));
  ({false, true}).forEach(print);
  ({false, true}).length;
  ({false, true}).length.toString();
  ({1, 2, 3}) + {4};
  ({1, 2, 3}).cast<num>;
  /* comment */ ({1, 2, 3}).length;
  // comment
  ({1, 2, 3}).length;
  print(({1, 2, 3}).length); // LINT
  ([false, true]).forEach(print); // LINT
  (0.sign).isEven; // LINT
  (0.isEven).toString(); // LINT
  (0.toString()).isEmpty; // LINT
  (0.toDouble()).toString(); // LINT

  List<String> list = <String>[];
  (list[list.length]).toString(); // LINT

  (a?.sign).hashCode;
  (a?.abs()).hashCode;
  (a?..abs()).hashCode;
  (a?[0]).hashCode;

  (a?.sign.sign).hashCode;
  (a?.abs().abs()).hashCode;
  (a
        ?..abs()
        ..abs())
      .hashCode;
  (a?[0][1]).hashCode;

  (a?.sign)!;
  (a?.abs())!;
  (a?..abs())!;
  (a?[0])!;

  print(!({"a": "b"}["a"]!.isEmpty)); // LINT

  print('a'.substring((1 == 1 ? 2 : 3), 4)); // OK
  var a1 = (1 == 1 ? 2 : 3); // OK

  var a2 = (1 == 1); // OK
  a2 = (1 == 1); // OK
  a2 = (1 == 1) || "".isEmpty; // OK
  var a3 = (1 + 1); // LINT

  // Tests for Literal and PrefixedIdentifier
  var a4 = (''); // LINT
  var a5 = ((a4.isEmpty), 2); // LINT
  var a6 = (1, (2)); // LINT

  /*withManyArgs((''), false, 1); // LIxNT
  withManyArgs('', (a4.isEmpty), 1); // LIxNT
  withManyArgs('', (''.isEmpty), 1); // LIxNT
  withManyArgs('', false, (1)); // LIxNT

  var a7 = (double.infinity).toString(); // LIxNT

  var list2 = ["a", null];
  var a8 = (list2.first)!.length; // LIxNT*/

  // Null-aware index expression before `:` needs to be parenthesized to avoid
  // being interpreted as a conditional expression.
  var a9 = a ? (b?[c]) : d; // OK
  var a10 = {(a?[b]): c}; // OK
}

void withManyArgs(String a, bool b, int c) {}

void testTernaryAndEquality() {
  if ((1 == 1 ? true : false)) // LINT
  {
    //
  } else if ((1 == 1 ? true : false)) // LINT
  {
    //
  }
  while ((1 == 1)) // LINT
  {
    print('');
  }
  switch ((5 == 6)) // LINT
  {
    case true:
      return;
    default:
      return;
  }
}

Invocation? invocation() => null;

bool Function(dynamic) get fn => (x) => x is bool ? x : false;

extension<T> on Set<T> {
  Set<T> operator +(Set<T> other) => {...this, ...other};
}

class MyType extends Type {
  MyType.withString(String s) {}
  MyType.withSelf(MyType myType) : this.withString((myType.toString)()); // LINT
}
