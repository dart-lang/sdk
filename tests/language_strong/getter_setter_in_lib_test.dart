// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library GetterSetterInLibTest;

import "package:expect/expect.dart";
import 'getter_setter_in_lib.dart';
import 'getter_setter_in_lib2.dart';
import 'getter_setter_in_lib3.dart' as L3;

main() {
  Expect.equals(42, foo);
  foo = 43;
  Expect.equals(42, foo);

  Expect.equals(77, bar);
  bar = 43;
  Expect.equals(77, bar);

  Expect.equals(L3.bar, 33);
  L3.bar = 44;
  Expect.equals(L3.bar, 44);
}
