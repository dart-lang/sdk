// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Canary test to check that set literals are not enabled *without* an
// experimental flag.

// Remove this test when the set literals feature is enabled without a flag.

main() {
  var _ = {1}; //# 01: compile-time error
  var _ = <int>{}; //# 02: compile-time error
  Set _ = {}; //# 03: compile-time error
  Set _ = <int>{}; //# 04: compile-time error
  var _ = const {1}; //# 05: compile-time error
  var _ = const <int>{}; //# 06: compile-time error
  Set _ = const {}; //# 07: compile-time error
  Set _ = const <int>{}; //# 08: compile-time error
  const _ = {1}; //# 09: compile-time error
  const _ = <int>{}; //# 10: compile-time error
  const Set _ = {}; //# 11: compile-time error
  const Set _ = <int>{}; //# 12: compile-time error
}
