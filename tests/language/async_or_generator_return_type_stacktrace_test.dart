// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void badReturnTypeAsync() async {} // //# 01: static type warning
void badReturnTypeAsyncStar() async* {} // //# 02: static type warning
void badReturnTypeSyncStar() sync* {} // //# 03: static type warning

main() {
  try {
    badReturnTypeAsync(); // //# 01: continued
  } catch (e, st) {
    Expect.isTrue(e is TypeError, "wrong exception type");
    Expect.isTrue(
        st.toString().contains("badReturnTypeAsync"), "missing frame");
  }

  try {
    badReturnTypeAsyncStar(); // //# 02: continued
  } catch (e, st) {
    Expect.isTrue(e is TypeError, "wrong exception type");
    Expect.isTrue(
        st.toString().contains("badReturnTypeAsyncStar"), "missing frame");
  }

  try {
    badReturnTypeSyncStar(); // //# 03: continued
  } catch (e, st) {
    Expect.isTrue(e is TypeError, "wrong exception type");
    Expect.isTrue(
        st.toString().contains("badReturnTypeSyncStar"), "missing frame");
  }
}
