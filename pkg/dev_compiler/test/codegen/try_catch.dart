// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  try {
    throw "hi there";
  } on String catch (e, t) {
  } catch (e, t) {
    rethrow;
  }
}

bar() {
  try {
    throw "hi there";
  } catch (e, t) {
  } on String catch (e, t) {
    // unreachable
    rethrow;
  }
}

baz() {
  try {
    throw "finally only";
  } finally {
    return true;
  }
}

qux() {
  try {
    throw "on only";
  } on String catch (e, t) {
    // unreachable
    rethrow;
  }
}

main() {
  foo();
  bar();
  baz();
  qux();
}
