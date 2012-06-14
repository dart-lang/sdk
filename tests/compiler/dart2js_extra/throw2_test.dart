// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void throw1() {
  throw "foo";
}

void throw2() {
  if (true) throw "foo";
}

void throw3() {
  if (false) {
    print("argh");
  } else {
    throw "foo";
  }
}

void throw4() {
  if (true) {
    throw "foo";
  } else {
    throw "bar";
  }
}

void nonThrow5() {
  if (false) throw "foo";
}

void main() {
  throw1();  /// 01: runtime error
  throw2();  /// 02: runtime error
  throw3();  /// 03: runtime error
  throw4();  /// 04: runtime error
  nonThrow5();
}
