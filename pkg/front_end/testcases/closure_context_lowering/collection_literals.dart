// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(Map<String, dynamic> m) {
  // The static type of `m` and the static type of the map literal it's spread
  // into aren't equal (Map<String, dynamic> and Map<String, String>
  // correspondingly), which causes the lowering to unfold the spread into a
  // for-in loop.
  return <String, String>{"key": "value", ...m};
}


test2(Map<String, String> m) {
  // The static type of `m` and the static type of the map literal it's spread
  // into are equal (Map<String, String> and Map<String, String>
  // correspondingly), which causes the lowering to unfold the spread into a
  // call to the `addAll` member.
  return <String, String>{"key": "value", ...m};
}
