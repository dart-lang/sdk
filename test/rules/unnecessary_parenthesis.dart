// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_parenthesis`

import 'dart:async';

var a,b,c,d;

main() async {
  1; // OK
  (1); // LINT
  print(1); // OK
  print((1)); // LINT
  if (a && b || c && d) true; // OK
  if ((a && b) || c && d) true; // OK because it may be hard to know all precedence rules
  (await new Future.value(1)).toString(); // OK
  ('' as String).toString(); // OK
  !(true as bool); // OK
  a = (a); // LINT
  (a) ? true : false; // LINT
  true ? (a) : false; // LINT
  true ? true : (a); // LINT
  (true ? [] : [])..add(''); // OK because it's unobvious it the same as without parens
  (a ?? true) ? true : true; // OK
  true ? [] : []..add(''); // OK
  m(p: (1 + 3)); // LINT
}

m({p}) => null;