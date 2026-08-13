// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo1(int outer1) {
  return () => outer1;
}

foo2(int outer2) {
  return ((int inner2) => (() => inner2))(outer2);
}

foo3({required int outer3}) {
  return () => outer3;
}

foo4(int outer4) {
  return (({required int inner4}) => (() => inner4))(inner4: outer4);
}
