// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that spread collections are not enabled without the experimental flag.

// TODO(rnystrom): Remove this test when the feature is enabled without a flag.

void main() {
  var _ = <int>[...<int>[1]]; //# 01: compile-time error
  var _ = <int, int>{...<int, int>{1: 1}}; //# 02: compile-time error
  var _ = <int>{...<int>{1}}; //# 03: compile-time error
  var _ = <int>[...?null]; //# 04: compile-time error
  var _ = <int, int>{...?null}; //# 05: compile-time error
  var _ = <int>{...?null}; //# 06: compile-time error
}
