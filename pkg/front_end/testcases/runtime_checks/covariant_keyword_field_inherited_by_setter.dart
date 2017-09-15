// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  num x;
}

class D implements C {
  covariant int /*@covariance=explicit*/ x;
}

class E implements D {
  int get x => 0;
  void set x(int /*@covariance=explicit*/ value) {}
}

main() {}
