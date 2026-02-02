// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

notCaptured(int aNotCaptured) {
  return;
}

directCaptured(int aCaptured) {
  return () => aCaptured;
}

assertCaptured1(int aAssertCaptured1) {
  assert((() => aAssertCaptured1 == 0)());
  return;
}

assertCaptured2(int aAssertCaptured2) {
  return () {
    assert((() => aAssertCaptured2 == 0)());
  };
}

directOverridingAssertCaptured1(int aDirectOverridingAssertCaptured1) {
  assert((() => aDirectOverridingAssertCaptured1 == 0)());
  return () => aDirectOverridingAssertCaptured1;
}

directOverridingAssertCaptured2(int aDirectOverridingAssertCaptured2) {
  return () {
    assert((() => aDirectOverridingAssertCaptured2 == 0)());
    return () => aDirectOverridingAssertCaptured2;
  };
}

directOverridingAssertCaptured3(int aDirectOverridingAssertCaptured3) {
  return () {
    assert(aDirectOverridingAssertCaptured3 == 0);
    return () => aDirectOverridingAssertCaptured3;
  };
}
