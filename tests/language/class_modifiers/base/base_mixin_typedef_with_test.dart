// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow typedef base mixins to be mixed in by multiple classes in the same
// library.

import 'package:expect/expect.dart';
import 'base_mixin_typedef_with_lib.dart';

main() {
  Expect.equals(1, A().foo);
}
