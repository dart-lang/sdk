// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow final classes to be implemented by multiple classes inside its
// library.

import 'package:expect/expect.dart';
import 'final_class_implement_lib.dart';

main() {
  Expect.equals(1, AImpl().foo);
  Expect.equals(1, B().foo);
  Expect.equals(0, EnumInside.x.index);
}
