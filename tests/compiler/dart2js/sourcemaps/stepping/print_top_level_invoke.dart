// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  print(/*bc:1*/ foo());
}

foo() {
  /*s:2*/ return "foo!";
/*s:3*/
}
