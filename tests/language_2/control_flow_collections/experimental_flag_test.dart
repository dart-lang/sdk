// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that control flow is not enabled without the experimental flag.

// Do enable set literals, just not the new syntax in them.
// SharedOptions=--enable-experiment=set-literals

// TODO(rnystrom): Remove this test when the feature is enabled without a flag.

void main() {
  var _ = <int>[if (true) 1]; //# 01: compile-time error
  var _ = <int, int>{if (true) 1: 1}; //# 02: compile-time error
  var _ = <int>{if (true) 1}; //# 03: compile-time error

  var _ = <int>[if (true) 1 else 2]; //# 04: compile-time error
  var _ = <int, int>{if (true) 1: 1 else 2: 2}; //# 05: compile-time error
  var _ = <int>{if (true) 1 else 2}; //# 06: compile-time error

  var _ = <int>[for (var i in []) 1]; //# 07: compile-time error
  var _ = <int, int>{for (var i in []) 1: 1}; //# 08: compile-time error
  var _ = <int>{for (var i in []) 1}; //# 09: compile-time error

  var _ = <int>[for (; false;) 1]; //# 10: compile-time error
  var _ = <int, int>{for (; false;) 1: 1}; //# 11: compile-time error
  var _ = <int>{for (; false;) 1}; //# 12: compile-time error

  () async {
    var _ = <int>[await for (var i in []) 1]; //# 13: compile-time error
    var _ = <int, int>{await  for (var i in []) 1: 1}; //# 14: compile-time error
    var _ = <int>{await for (var i in []) 1}; //# 15: compile-time error
  }();
}
