// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing access to private fields.

part of Private3Test.dart;

main() {
  PrivateMain.main();
}

class PrivateMain {
  static const _myPrecious = "A Ring";

  static accessMyPrivates() {
    var value;
    value = 0;
    try {
      value = _myPrecious;
    } catch (e) {
      value = -1;
    }
    Expect.equals("A Ring", value);
  }

  static accessMyLibPrivates() {
    var value;
    value = 0;
    var the_other = new PrivateOther();
    try {
      value = the_other._myPrecious;
    } catch (e, trace) {
      print(e);
      print(trace);
      Expect.equals(true, e is NoSuchMethodError);
      value = -1;
    }
    Expect.equals("Another Ring", value);
  }

  static accessOtherLibPrivates() {
    var value;
    value = 0;
    var the_other = new PrivateLib();
    try {
      value = (the_other as dynamic)._myPrecious;
    } catch (e, trace) {
      print(e);
      print(trace);
      Expect.equals(true, e is NoSuchMethodError);
      value = -1;
    }
    Expect.equals(-1, value);
  }

  static main() {
    accessMyPrivates();
    accessMyLibPrivates();
    accessOtherLibPrivates();
  }
}
