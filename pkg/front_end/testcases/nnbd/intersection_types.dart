// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks the computation of the nullabilities of intersection types.

class A {}
class B extends A {}
class C extends B {}

class Foo<T extends A?> {
  doPromotionsToNullable(T t) {
    if (t is B?) {
      var bar = t;
      if (t is C?) {
        var baz = t;
      }
    }
  }

  doPromotionsToNonNullable(T t) {
    if (t is B) {
      var bar = t;
      if (t is C) {
        var baz = t;
      }
    }
  }
}

main() {}
