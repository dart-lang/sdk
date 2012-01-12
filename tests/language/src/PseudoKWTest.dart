// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we can use pseudo keywords as names in function level code.


class PseudoKWTest {
  static testMain() {

    // This is a list of built-in identifiers from the Dart spec.
    // It sanity checks that these pseudo-keywords are legal identifiers.

    var abstract = 0;
    var assert = 0;
    var call = 0;
    var Dynamic = 0;
    var factory = 0;
    var get = 0;
    var implements = 0;
    var import = 0;
    var interface = 0;
    var library = 0;
    var negate = 0;
    var operator = 0;
    var set = 0;
    var source = 0;
    var static = 0;
    var typedef = 0;

    // "native" is a per-implementation extension that is not a part of the
    // Dart language.  While it is not an official built-in identifier, it
    // is useful to ensure that it remains a legal identifier.
    var native = 0;


    // The code below adds a few additional variants of usage without any
    // attempt at complete coverage.
    {
      void factory(set) {
        return 0;
      }
    }

    get: while (import > 0) {
      break get;
    }

    return static + library * operator;
  }
}


main() {
  PseudoKWTest.testMain();
}
