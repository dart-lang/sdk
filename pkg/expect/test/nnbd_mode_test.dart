// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final bool strong = () {
  try {
    int i = null as dynamic;
    return false;
  } catch (e) {
    return true;
  }
}();

void main() {
  Expect.equals(strong, hasSoundNullSafety);
  Expect.equals(!strong, hasUnsoundNullSafety);
}
