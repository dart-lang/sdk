// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Allow typedef sealed mixins to be mixed in by classes in the same library.

import "package:expect/expect.dart";
import 'sealed_mixin_typedef_lib.dart';

main() {
  var a = A();
  Expect.equals(0, a.foo);
}
