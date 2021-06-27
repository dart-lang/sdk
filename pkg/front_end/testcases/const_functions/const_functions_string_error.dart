// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous string usage with const functions.

import "package:expect/expect.dart";

const String str = "str";
const var1 = str[-1];
const var2 = str[3];

const var3 = fn();
fn() {
  String s = "str";
  return str[-1];
}

const var4 = fn2();
fn2() {
  String s = "str";
  return str[3];
}

const var5 = fn3();
fn3() {
  String s = "str";
  return str[1.1];
}

void main() {}
