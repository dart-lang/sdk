// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

class GetName {
  set flif(_) => "flif=";
}

int getName(im) => reflect(new GetName()).delegate(im);

class C {
  var im;
  noSuchMethod(im) => this.im = im;
  flif() {}
}

main() {
  dynamic c = new C();
  c.flif = 42;
  Expect.equals(42, getName(c.im));
  Expect.equals(42, c.im.positionalArguments[0]);
}
