// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base mixins to be mixed by multiple classes outside its library.

import 'package:expect/expect.dart';
import 'base_mixin_with_lib.dart';

abstract base class AOutside with BaseMixin {}

base class AOutsideImpl extends AOutside {}

base class BOutside with BaseMixin {}

enum EnumOutside with MixinForEnum { x }

main() {
  Expect.equals(0, AOutsideImpl().foo);
  Expect.equals(0, BOutside().foo);
  Expect.equals(0, EnumOutside.x.index);
}
