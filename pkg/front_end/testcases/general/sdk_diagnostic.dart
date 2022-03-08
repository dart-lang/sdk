// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C extends Iterable<Object> {
  // Missing implementation of [iterator] leads to diagnostic which refers to
  // the SDK. This test is intended to test that such references are displayed
  // correctly.
}

test() {
  print(incorrectArgument: "fisk");
}

main() {}
