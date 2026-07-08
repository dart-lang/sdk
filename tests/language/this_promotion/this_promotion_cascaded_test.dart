// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

// This test verifies that promoting an already-promoted `this` behaves
// correctly. That is, the decision of whether to promote should be based on
// whether the tested type is a subtype of the _previously promoted_ type, not
// whether it's a subtype of the original type of `this`.

import 'package:expect/static_type_helper.dart';

class C {
  void test() {
    if (this is D) {
      this.expectStaticType<Exactly<D>>;
      if (this is E) {
        // Cannot promote D to E, since E is not a subtype of D.
        this.expectStaticType<Exactly<D>>;
      }
      if (this is F) {
        // Can promote D to F, since F is a subtype of D.
        this.expectStaticType<Exactly<F>>;
      }
    }
  }
}

class D extends C {}

class E extends C {}

class F extends D {}

extension on C {
  void testExtension() {
    if (this is D) {
      this.expectStaticType<Exactly<D>>;
      if (this is E) {
        // Cannot promote D to E, since E is not a subtype of D.
        this.expectStaticType<Exactly<D>>;
      }
      if (this is F) {
        // Can promote D to F, since F is a subtype of D.
        this.expectStaticType<Exactly<F>>;
      }
    }
  }
}

main() {
  C().test();
  C().testExtension();
}
