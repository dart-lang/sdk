// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we can still use `base` as an identifier for mixin names.

import 'package:expect/expect.dart';

mixin class base {
  int x = 0;
}

main() {
  Expect.equals(0, base().x);
}
