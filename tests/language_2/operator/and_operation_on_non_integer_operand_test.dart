// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to miscompile boolean add operations
// if one of the operands was an int and the other was not (issue 22427).

import "package:expect/expect.dart";

class NotAnInt {
  NotAnInt operator &(b) => this;
}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
id(x) => x;

main() {
  var a = id(new NotAnInt());
  Expect.equals(a, a & 5 & 2);
}
