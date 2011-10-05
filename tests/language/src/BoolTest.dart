// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing basic boolean properties.

class BoolTest {
  static void testEquality() {
    Expect.equals(true, true);
    Expect.equals(false, false);
    Expect.equals(true, true === true);
    Expect.equals(false, true === false);
    Expect.equals(true, false === false);
    Expect.equals(false, false === true);
    Expect.equals(false, true !== true);
    Expect.equals(true, true !== false);
    Expect.equals(false, false !== false);
    Expect.equals(true, false !== true);
    Expect.equals(true, true == true);
    Expect.equals(false, true == false);
    Expect.equals(true, false == false);
    Expect.equals(false, false == true);
    Expect.equals(false, true != true);
    Expect.equals(true, true != false);
    Expect.equals(false, false != false);
    Expect.equals(true, false != true);
    Expect.equals(true, true === (true == true));
    Expect.equals(true, false === (true == false));
    Expect.equals(true, true === (false == false));
    Expect.equals(true, false === (false == true));
    Expect.equals(false, true !== (true == true));
    Expect.equals(false, false !== (true == false));
    Expect.equals(false, true !== (false == false));
    Expect.equals(false, false !== (false == true));
    Expect.equals(false, false === (true == true));
    Expect.equals(false, true === (true == false));
    Expect.equals(false, false === (false == false));
    Expect.equals(false, true === (false == true));
    Expect.equals(true, false !== (true == true));
    Expect.equals(true, true !== (true == false));
    Expect.equals(true, false !== (false == false));
    Expect.equals(true, true !== (false == true));
    // Expect.equals could rely on a broken boolean equality.
    if (true == false) {
      throw "Expect.equals broken";
    }
    if (false == true) {
      throw "Expect.equals broken";
    }
    if (true === false) {
      throw "Expect.equals broken";
    }
    if (false === true) {
      throw "Expect.equals broken";
    }
    if (true == true) {
    } else {
      throw "Expect.equals broken";
    }
    if (false == false) {
    } else {
      throw "Expect.equals broken";
    }
    if (true === true) {
    } else {
      throw "Expect.equals broken";
    }
    if (false === false) {
    } else {
      throw "Expect.equals broken";
    }
    if (true != false) {
    } else {
      throw "Expect.equals broken";
    }
    if (false != true) {
    } else {
      throw "Expect.equals broken";
    }
    if (true !== false) {
    } else {
      throw "Expect.equals broken";
    }
    if (false !== true) {
    } else {
      throw "Expect.equals broken";
    }
    if (true != true) {
      throw "Expect.equals broken";
    }
    if (false != false) {
      throw "Expect.equals broken";
    }
    if (true !== true) {
      throw "Expect.equals broken";
    }
    if (false !== false) {
      throw "Expect.equals broken";
    }
  }

  static void testToString() {
    Expect.equals("true", true.toString());
    Expect.equals("false", false.toString());
  }

  static void testMain() {
    testEquality();
    testToString();
  }
}

main() {
  BoolTest.testMain();
}
