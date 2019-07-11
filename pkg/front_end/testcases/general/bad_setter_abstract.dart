// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

set b();

set c(x, y);

class A {
  set a();
  set d(x, y);
}

abstract class B {
  set a();
  set d(x, y);
}

main() {
  bool threw;
  try {
    threw = true;
    new A().a = null;
    threw = false;
  } catch (e) {
    // Ignored.
  }
  if (!threw) {
    throw "Expected an error above.";
  }
  try {
    threw = true;
    new A().d = null;
    threw = false;
  } catch (e) {
    // Ignored.
  }
  if (!threw) {
    throw "Expected an error above.";
  }
  try {
    threw = true;
    b = null;
    threw = false;
  } catch (e) {
    // Ignored.
  }
  if (!threw) {
    throw "Expected an error above.";
  }
  if (!threw) {
    throw "Expected an error above.";
  }
  try {
    threw = true;
    c = null;
    threw = false;
  } catch (e) {
    // Ignored.
  }
  if (!threw) {
    throw "Expected an error above.";
  }
  try {
    threw = true;
    new B();
    threw = false;
  } on AbstractClassInstantiationError catch (_) {
    // Ignored.
  }
  if (!threw) {
    throw "Expected an error above.";
  }
}
