// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow typedef in different library, used by class in library.

import 'package:expect/expect.dart';
import 'base_class_typedef_outside_of_library_lib.dart';

main() {
  Expect.equals(0, A().foo);
  Expect.equals(1, B().foo);
}
