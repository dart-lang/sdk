// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var record = (1, "a", $5: true);
  var dynamicRecord = record as dynamic;
  Expect.type<(int, String, {bool $5})>(record);
  Expect.equals(1, record.$1);
  Expect.equals("a", record.$2);
  Expect.equals(true, record.$5);

  // Extension methods apply.
  Expect.equals("0", record.$0);
  Expect.equals("3", record.$3);
  Expect.equals("2p64", record.$18446744073709551616);
  Expect.equals("2p64+1", record.$18446744073709551617);

  // Dynamic access starts at $1.
  Expect.equals(1, dynamicRecord.$1);
  Expect.equals("a", dynamicRecord.$2);
  Expect.equals(true, dynamicRecord.$5);

  // Extension methods do not apply to `dynamic`. Record does not have getter.
  Expect.throwsNoSuchMethodError(() => dynamicRecord.$0);
  Expect.throwsNoSuchMethodError(() => dynamicRecord.$3);
  Expect.throwsNoSuchMethodError(() => dynamicRecord.$18446744073709551616);
  Expect.throwsNoSuchMethodError(() => dynamicRecord.$18446744073709551617);

  // Named field `$0` wont conflict with positional field.
  var zeroRecord = (1, $0: 2); // Allowed as named field.
  Expect.equals(1, zeroRecord.$1);
  Expect.equals(2, zeroRecord.$0);

  // No int64 overflow.
  var bigRecord = (1, $18446744073709551617: 2);
  Expect.equals(1, bigRecord.$1);
  Expect.equals(2, bigRecord.$18446744073709551617);

  // Tests that rely on unqualified `$n` to apply to `this`.
  record.testExtensionMethod();
}

// Add positional-like extension members.
extension Extension<A, B, C> on (A, B, {C $5}) {
  String get $0 => "0";
  Never get $1 => throw "shadowed";
  String get $3 => "3";
  String get $18446744073709551616 => "2p64";
  String get $18446744073709551617 => "2p64+1";

  // Check that direct, unqualified access works inside extension.
  void testExtensionMethod() {
    Expect.equals("0", $0);
    Expect.throws<String>(() => $1, (e) => e == "shadowed");
    Expect.equals("a", $2);
    Expect.equals("3", $3);
    Expect.equals(true, $5);
    Expect.equals("2p64", $18446744073709551616);
    Expect.equals("2p64+1", $18446744073709551617);
  }
}
