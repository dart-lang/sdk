// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `out` and `inout` are built-in identifiers. They can be used as method or
// variable names.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class OutMembers {
  var out = 3;
  int func(int out) {
    return out;
  }
}

class OutMethod {
  int out() => 1;
}

class InoutMembers {
  var inout = 3;
  int func(int inout) {
    return inout;
  }
}

class InoutMethod {
  int inout() => 1;
}

var out = 5;
var inout = 5;

main() {
  OutMembers outMembers = OutMembers();
  Expect.equals(2, outMembers.func(2));
  Expect.equals(3, outMembers.out);

  InoutMembers inoutMembers = InoutMembers();
  Expect.equals(2, inoutMembers.func(2));
  Expect.equals(3, inoutMembers.inout);

  Expect.equals(1, OutMethod().out());
  Expect.equals(1, InoutMethod().inout());

  Expect.equals(5, out);
  Expect.equals(5, inout);
}
