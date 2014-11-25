// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable_async
//
// Regression test for issue 21536.

import 'dart:async';
import 'package:expect/expect.dart';

later(vodka) => new Future.value(vodka);

manana(tequila) async => tequila;

main() async {
  var a = await later('Asterix').then((tonic) {
    return later(tonic);
  });
  var o = await manana('Obelix').then(manana);
  Expect.equals("$a and $o", "Asterix and Obelix");
}
