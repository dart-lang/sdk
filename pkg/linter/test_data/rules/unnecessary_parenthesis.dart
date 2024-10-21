// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

var a, b, c, d;

main() async {
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
