// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow typedef base mixins to be mixed in by multiple classes outside the
// library.

import 'package:expect/expect.dart';
import 'base_mixin_typedef_with_lib.dart';

abstract base class AOutside with BaseMixinTypeDef {}

class AOutsideImpl extends AOutside {}

base class BOutside with BaseMixinTypeDef {}

main() {
  Expect.equals(0, AOutsideImpl().foo);
  Expect.equals(0, BOutside().foo);
}
