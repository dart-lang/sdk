// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool typeChecksEnabled() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

bool assertionsEnabled() {
  try {
    assert(false);
    return false;
  } on AssertionError catch (e) {
    return true;
  }
  return false;
}

final bool typeChecksOn = typeChecksEnabled();
final bool assertionsOn = assertionsEnabled();

ifExpr(e) {
  if (e)
    return true;
  else
    return false;
}

bool ifNull() => ifExpr(null);
bool ifString() => ifExpr("true");

main() {
  print("type checks: $typeChecksOn");
  print("assertions:  $assertionsOn");

  if (typeChecksOn) {
    Expect.throws(ifNull, (e) => e is AssertionError);
  }
  if (assertionsOn && !typeChecksOn) {
    Expect.throws(ifNull, (e) => e is AssertionError);
  }
  if (!typeChecksOn && !assertionsOn) {
    Expect.identical(false, ifNull());
  }

  if (!typeChecksOn) {
    Expect.identical(false, ifString());
  }
  if (typeChecksOn) {
    Expect.throws(ifString, (e) => e is TypeError);
  }
}
