// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Requirements=nnbd-strong

import 'package:expect/expect.dart';
import 'mixed_bottom_type_lib.dart';

main() {
  // The subtype check `void Function(String) <: void Function(Null)` should be
  // false in strong mode semantics since `Null </: String`.
  Expect.isFalse(stringFunction is void Function(Null));
}
