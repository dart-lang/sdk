// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow mixing-in mixin classes and non-mixin classes in a part file of the
// same library.

import 'package:expect/expect.dart';
part 'mixin_class_part_lib.dart';

mixin class MixinClass {
  int foo = 0;
}

class BImpl extends B {}

main() {
  Expect.equals(0, A().foo);
  Expect.equals(0, BImpl().foo);
}
