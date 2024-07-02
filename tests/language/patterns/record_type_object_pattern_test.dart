// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef R3<A, B, C> = (A, B, {C $5});

void main() {
  var record = (1, "a", $5: true);
  var dynamicRecord = record as dynamic;

  switch (dynamicRecord) {
    // Record pattern
    case (int a, String b, $5: bool c):
      Expect.equals(1, a);
      Expect.equals("a", b);
      Expect.equals(true, c);
    case _: Expect.fail("Didn't match full record pattern");
  }

  switch (dynamicRecord) {
    // Object pattern.
    case R3<int, String, bool>(:var $1, :var $2, :var $5):
      Expect.equals(1, $1);
      Expect.equals("a", $2);
      Expect.equals(true, $5);
    case _: Expect.fail("Didn't match Object pattern");
  }

  switch (dynamicRecord) {
    // Partial object pattern.
    case R3<int, String, bool>(:var $1, :var $5):
      Expect.equals(1, $1);
      Expect.equals(true, $5);
    case _: Expect.fail("Didn't match partial Object pattern");
  }

  switch (dynamicRecord) {
    // Object pattern with extension getters.
    case R3<int, String, bool>(
        :var $1, :var $3, :var $5, :var $18446744073709551617):
      Expect.equals(1, $1);
      Expect.equals("3", $3);
      Expect.equals(true, $5);
      Expect.equals("2p64+1", $18446744073709551617);
    case _: Expect.fail("Didn't match object pattern with extension getters");
  }
}

// Add positional-like extension members.
extension Extension<A, B, C> on (A, B, {C $5}) {
  String get $0 => "0";
  Never get $1 => throw "shadowed";
  String get $3 => "3";
  String get $18446744073709551616 => "2p64";
  String get $18446744073709551617 => "2p64+1";
}
