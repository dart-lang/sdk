// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

class FBound<F extends FBound<F>> {}

class Bar extends FBound<Bar> {}

class SubBar extends Bar {}

class Baz<T> extends FBound<Baz<T>> {}

class SubBaz<T> extends Baz<T> {}


isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch(var e) {
    return true;
  }
}

main() {
  FBound<Bar> fb = new FBound<Bar>();
  {
    bool got_type_error = false;
    try {
      FBound<SubBar> fsb = new FBound<SubBar>();  /// 01: static type warning
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());  /// 01: continued
  }
  FBound<Baz<Bar>> fbb = new FBound<Baz<Bar>>();
  {
    bool got_type_error = false;
    try {
      FBound<SubBaz<Bar>> fsb = new FBound<SubBaz<Bar>>();  /// 02: static type warning
    } catch (TypeError error) {
      got_type_error = true;
    }
    // Type error in checked mode only.
    Expect.isTrue(got_type_error == isCheckedMode());  /// 02: continued
  }
}
