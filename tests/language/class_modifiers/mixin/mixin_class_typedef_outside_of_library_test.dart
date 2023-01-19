// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow typedef in different library, used by class in library.

import 'package:expect/expect.dart';
import 'mixin_class_typedef_outside_of_library_lib.dart';

class BImpl extends B {}

main() {
  Expect.equals(0, A().foo);
  Expect.equals(0, BImpl().foo);
}
