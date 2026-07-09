// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testNotCapturedImplicitTypes() {
  try {
    throw new StateError("error");
  } catch (e, s) {}
}

testNotCapturedExplicitTypes() {
  try {
    throw new StateError("error");
  } on StateError catch (e, s) {}
}

testNotCapturedWildcards() {
  try {
    throw new StateError("error");
  } catch (_, _) {}
}

testDirectCaptured() {
  try {
    throw new StateError("error");
  } catch (e, s) {
    return () => [e, s];
  }
}

testAssertCaptured() {
  try {
    throw new StateError("error");
  } catch (e, s) {
    return () {
      assert(e != null && s != null);
    };
  }
}

testErroneousOptional() {
  try {
    throw new StateError("error");
  } catch ([e, s]) {} // Error.
}

testErroneousOneOptional() {
  try {
    throw new StateError("error");
  } catch (e, [s]) {} // Error.
}

testErroneousNamed() {
  try {
    throw new StateError("error");
  } catch ({e, s}) {} // Error.
}
