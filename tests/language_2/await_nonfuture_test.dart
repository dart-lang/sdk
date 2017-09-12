// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=5

import 'package:expect/expect.dart';

var X = 0;

foo() async {
  Expect.equals(X, 10); // foo runs after main returns.
  return await 5;
}

main() {
  var f = foo();
  f.then((res) => print("f completed with $res"));
  X = 10;
}
