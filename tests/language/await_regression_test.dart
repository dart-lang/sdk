// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable_async
//


import 'dart:async';
import 'package:expect/expect.dart';

later(vodka) => new Future.value(vodka);

manana(tequila) async => tequila;

// Regression test for issue 21536.
testNestedFunctions() async {
  var a = await later('Asterix').then((tonic) {
    return later(tonic);
  });
  var o = await manana('Obelix').then(manana);
  Expect.equals("$a and $o", "Asterix and Obelix");
}

addLater({a, b}) => new Future.value(a + b);

// Regression test for issue 21480.
testNamedArguments() async {
  var sum = await addLater(a:5, b:10);
  Expect.equals(sum, 15);
  sum = await addLater(b:11, a:-11);
  Expect.equals(sum, 0);
}

main() async {
  testNestedFunctions();
  testNamedArguments();
}
