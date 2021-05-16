// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=
// VMOptions=--use_slow_path

import "package:expect/expect.dart";

@pragma("vm:never-inline")
dynamic hiddenSmi() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenMint() {
  try {
    throw 0x8000000000000000;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenDouble() {
  try {
    throw 3.0;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenCustom() {
  try {
    throw new Custom();
  } catch (e) {
    return e;
  }
  return 0;
}

class Custom {
  operator <(other) => "lt";
  operator >(other) => "gt";
  operator <=(other) => "le";
  operator >=(other) => "ge";
  operator ==(other) => false;
}

main() {
  Expect.equals(false, hiddenSmi() < 2);
  Expect.equals(true, hiddenSmi() > 2);
  Expect.equals(false, hiddenSmi() <= 2);
  Expect.equals(true, hiddenSmi() >= 2);
  Expect.equals(false, hiddenSmi() == 2);
  Expect.equals(true, hiddenSmi() != 2);

  Expect.equals(true, hiddenMint() < 2);
  Expect.equals(false, hiddenMint() > 2);
  Expect.equals(true, hiddenMint() <= 2);
  Expect.equals(false, hiddenMint() >= 2);
  Expect.equals(false, hiddenMint() == 2);
  Expect.equals(true, hiddenMint() != 2);

  Expect.equals(false, hiddenDouble() < 2);
  Expect.equals(true, hiddenDouble() > 2);
  Expect.equals(false, hiddenDouble() <= 2);
  Expect.equals(true, hiddenDouble() >= 2);
  Expect.equals(false, hiddenDouble() == 2);
  Expect.equals(true, hiddenDouble() != 2);

  Expect.equals("lt", hiddenCustom() < 2);
  Expect.equals("gt", hiddenCustom() > 2);
  Expect.equals("le", hiddenCustom() <= 2);
  Expect.equals("ge", hiddenCustom() >= 2);
  Expect.equals(false, hiddenCustom() == 2);
  Expect.equals(true, hiddenCustom() != 2);
}
