// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class E {
  foo() {
    super[4] = 42;
    super[4] += 5;
    return super[2];
  }
}

beforeTestMissingTry () {
  // Referring to this function before it has been resolved would lead to a
  // crash.
  testMissingTry();
}

testMissingTry() {
  on Exception catch (e) { }
}

main() {
}
