// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error*/

class C {
  void set x(value) {}
}

void test(C c) {
  c.x = 1; // Ok
  c. /*@error=UndefinedGetter*/ x += 1;
  c. /*@error=UndefinedGetter*/ x ??= 1;
}

main() {}
