// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library private_selector_test;

import "package:expect/expect.dart";
import 'private_selector_lib.dart';

class B extends A {}

main() {
  new A().public();
  Expect.isTrue(executed);
}
