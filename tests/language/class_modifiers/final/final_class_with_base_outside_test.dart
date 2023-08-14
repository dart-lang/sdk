// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow `final` class with a `base` mixin outside its library.

import 'package:expect/expect.dart';
import 'final_class_base_class_lib.dart';

final class A with BaseMixin {}

main() {
  Expect.equals(0, A().foo);
}
