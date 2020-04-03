// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

abstract class I {
  interfaceMethod();
}

class C implements I {
  noSuchMethod(_) => "C";
}

class D extends C {
  noSuchMethod(_) => "D";
  dMethod() => super.interfaceMethod();
}

main() {
  var result = new D().dMethod();
  if (result != "D") throw "Expected 'D' but got: '$result'";
}
