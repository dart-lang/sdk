// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 9442.

typedef dynamic GetFromThing<T extends Thing>(T target);

typedef GetFromThing<T> DefGetFromThing<T extends Thing>(dynamic def);

class Thing {}

class Test {
  static final DefGetFromThing<Thing> fromThing = (dynamic def) {};
}

main() {
  Test.fromThing(10);
}
