// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  /*bl*/
  /*s:1*/ foo();
  /*s:4*/
}

foo() /*sl:2*/ async {
  print("hello from foo");
/*s:3*/
}
