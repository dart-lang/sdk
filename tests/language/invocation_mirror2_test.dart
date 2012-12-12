// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  var im;
  noSuchMethod(im) => this.im = im;
  flif() {}
}

main() {
 var c = new C();
 c.flif = 42;
 Expect.equals('flif=', c.im.memberName);
 Expect.equals(42, c.im.positionalArguments[0]);
}
