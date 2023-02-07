// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow final mixins to be implemented by multiple classes in the same library.

import 'package:expect/expect.dart';
import 'final_mixin_implement_lib.dart';

main() {
  Expect.equals(1, AImpl().foo);
  Expect.equals(1, B().foo);
  Expect.equals(0, EnumInside.x.index);
}
