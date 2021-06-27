// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'super_set_from_opt_in_lib.dart';

abstract class Class extends SuperClass {
  // This will have a member signature for `property=` that should _not_ be
  // the target of `super.property = value` below.
}

class SubClass extends Class {
  @override
  set property(Object value) {
    super.property = value;
  }
}

main() {
  new SubClass().property = null;
}
