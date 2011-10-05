// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we can use pseudo keywords as names in function level code.


class PseudoKWTest {
  static testMain() {

    // This list is taken from the 'identifier' production
    // of the Dart grammar. It lists all the pseudo-keywords
    // that are legal identifiers at the function level.

    var abstract = 0;
    var class = 0;
    var extends = 0;
    var factory = 0;
    var get = 0;
    var implements = 0;
    var import = 0;
    var interface = 0;
    var library = 0;
    var native = 0;
    var negate = 0;
    var operator = 0;
    var set = 0;
    var source = 0;
    var static = 0;
    {
      void factory(set) {
        return 0;
      }
    }

    get: while (extends > 0) {
      break get;
    }

    return static + library * class;
  }
}


main() {
  PseudoKWTest.testMain();
}
