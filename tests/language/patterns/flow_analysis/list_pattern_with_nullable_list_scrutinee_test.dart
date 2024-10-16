// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises a corner case of list pattern handling where the type of
// the scrutinee is a nullable list. Prior to fixing
// https://github.com/dart-lang/sdk/issues/55543, flow analysis would fail to
// account for the fact that a list pattern might fail to match due to a list
// length mismatch, so it would incorrectly conclude that in the "match failure"
// case, the scrutinee was `null`.

import "package:expect/static_type_helper.dart";

test(List<Object?>? x) {
  switch (x) {
    case []:
      x.expectStaticType<Exactly<List<Object?>>>();
    default:
      x.expectStaticType<Exactly<List<Object?>?>>();
  }
}

main() {
  test(null);
  test([]);
}
