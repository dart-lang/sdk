// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C {
  void set x(num value) {}
}

class D extends C {
  void set x(covariant int /*@covariance=explicit*/ value) {}
}

class E implements D {
  int /*@covariance=explicit*/ x;
}

main() {}
