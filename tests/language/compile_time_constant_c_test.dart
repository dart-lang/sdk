// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final m1 = const {
  499: 400 + 99  /// 01: compile-time error
};
final m2 = const {
  "foo" + "bar": 42  /// 02: compile-time error
};

use(x) => x;

main() {
  use(m1);
  use(m2);
}
