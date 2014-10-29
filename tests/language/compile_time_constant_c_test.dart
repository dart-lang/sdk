// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const m1 = const {
  499: 400 + 99
};
const m2 = const {
  "foo" + "bar": 42 /// 01: compile-time error
};

use(x) => x;

main() {
  use(m1);
  use(m2);
}
