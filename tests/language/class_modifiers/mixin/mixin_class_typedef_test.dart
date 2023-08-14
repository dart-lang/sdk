// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow typedef mixin classes to be mixed in by classes in the same library.

import 'package:expect/expect.dart';
import 'mixin_class_typedef_lib.dart';

class ATypeDef with MixinClassTypeDef {}

abstract class BTypeDef with MixinClassTypeDef {}

class BTypeDefImpl extends BTypeDef {}

main() {
  Expect.equals(0, A().foo);
  Expect.equals(0, ATypeDef().foo);
  Expect.equals(0, BTypeDefImpl().foo);
}
