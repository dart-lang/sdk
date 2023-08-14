// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow interface classes to be extended by multiple classes inside its
// library.

import 'package:expect/expect.dart';
import 'interface_class_extend_lib.dart';

class AImpl extends A {}

main() {
  Expect.equals(0, AImpl().foo);
  Expect.equals(0, B().foo);
}
