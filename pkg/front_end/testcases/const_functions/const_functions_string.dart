// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests string usage with const functions.

import "package:expect/expect.dart";

const String str = "str";
const var1 = str[2];

const var2 = fn();
fn() {
  String local = "str";
  return local[0];
}

const var3 = "str"[0];

const var4 = fn2();
fn2() {
  try {
    var x = str[-1];
  } on RangeError {
    return 2;
  }
}

void main() {
  Expect.equals(var1, 'r');
  Expect.equals(var2, 's');
  Expect.equals(var3, 's');
  Expect.equals(var4, 2);
}
