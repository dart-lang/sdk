// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const m0 = const {
  499: 400 + 99
};
const m1 = const {
  "foo" + "bar": 42            /// 01: compile-time error
};
const m2 = const {
  "foo" * 4: 42                /// 02: compile-time error
};
const m3 = const {
  "foo".codeUnitAt(0): 42      /// 03: compile-time error
};

use(x) => x;

main() {
  use(m0);
  use(m1);
  use(m2);
  use(m3);
}
