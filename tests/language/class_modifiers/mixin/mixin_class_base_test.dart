// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base mixin classes.

import 'package:expect/expect.dart';

base mixin class BaseMixinClass {
  int foo = 0;
}

main() {
  Expect.equals(0, BaseMixinClass().foo);
}
