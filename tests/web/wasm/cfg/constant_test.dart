// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int returnInt() {
  return 42;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
double returnDouble() {
  return 3.14;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
bool returnBool() {
  return true;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
String returnString() {
  return 'hello';
}

void main() {
  Expect.equals(42, returnInt());
  Expect.equals(3.14, returnDouble());
  Expect.equals(true, returnBool());
  Expect.equals('hello', returnString());
}
