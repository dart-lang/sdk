// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M {
  var m;
}

mixin N on M {
  void set superM(value) {
    super.m = value;
  }

  get superM => super.m;
}

class S {}

class Named = S with M, N, M;

main() {
  Named named = new Named();
  named.m = 42;
  named.superM = 87;
  if (named.m != 42) {
    throw "Bad mixin translation of set:superM";
  }
  if (named.superM != 87) {
    throw "Bad mixin translation of get:superM";
  }
}
