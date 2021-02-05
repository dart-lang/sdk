// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Test derived from a broken co19 test
/// (LayoutTests/fast/mediastream/getusermedia_t01.dart). Caused dart2js to
/// crash.

foo() {}

gotStream1(stream) {
  foo()
      . //# 01: compile-time error
      .then();
}

void main() {
  print(gotStream1);
}
