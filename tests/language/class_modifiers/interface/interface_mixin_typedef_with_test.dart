// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow typedef interface mixins to be mixed in by multiple classes in the same
// library.

import 'package:expect/expect.dart';
import 'interface_mixin_typedef_with_lib.dart';

main() {
  Expect.equals(1, A().foo);
}
