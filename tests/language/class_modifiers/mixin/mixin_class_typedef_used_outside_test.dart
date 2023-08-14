// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow typedefs to be outside the mixed-in class' library.

import 'package:expect/expect.dart';
import 'mixin_class_typedef_used_outside_lib.dart';

typedef ATypeDef = MixinClass;

class A with ATypeDef {}

abstract class B with ATypeDef {}

class BImpl extends B {}

main() {
  Expect.equals(0, A().foo);
  Expect.equals(0, BImpl().foo);
}
