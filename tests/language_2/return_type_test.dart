// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int returnString1() => 's';  /*@compile-error=unspecified*/
void returnNull() => null;
void returnString2() => 's';  /*@compile-error=unspecified*/

main() {
  returnString1();
  returnNull();
  returnString2();
}
