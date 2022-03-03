// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

test(f) {
  if (f is void Function(Object, StackTrace)) return 1;
  if (f is void Function(Object)) return 10;
  if (f is void Function()) return 100;
}

main() {
  Expect.equals(
      111,
      test(() => null) +
          test((Object o) => null) +
          test((Object o, StackTrace t) => null));
}
