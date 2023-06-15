// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base classes to be extended by multiple classes outside its library.

import 'package:expect/expect.dart';
import 'base_class_extend_lib.dart';

abstract base class AOutside extends BaseClass {}

base class AOutsideImpl extends AOutside {}

base class BOutside extends BaseClass {}

main() {
  Expect.equals(0, AOutsideImpl().foo);
  Expect.equals(0, BOutside().foo);
}
