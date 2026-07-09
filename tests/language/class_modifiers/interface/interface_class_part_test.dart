// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow extending and implementing interface classes in a part file of
// the same library

import 'package:expect/expect.dart';
part 'interface_class_part_lib.dart';

interface class InterfaceClass {
  int foo = 0;
}

main() {
  Expect.equals(0, A().foo);
  Expect.equals(1, B().foo);
}
