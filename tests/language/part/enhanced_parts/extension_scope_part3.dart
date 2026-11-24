// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'extension_scope_test.dart';

import 'extension_scope_lib.dart' show EL3;
import 'extension_scope_lib.dart' as p1 show EL6B;

void part3Test() {
  Expect.equals("EL0", L0().name);
  Expect.equals("EL0", L1().name);
  Expect.equals("EL0", L2().name);
  Expect.equals("EL3", L3().name);
  Expect.equals("EL4", L4().name);
  Expect.equals("EL4", L5().name);
  Expect.equals("EL6B", L6().name);

  Expect.equals("EL0", EL0(L6()).name);
  Expect.equals("EL3", EL3(L6()).name);
  Expect.equals("EL4", p1.EL4(L6()).name);
  Expect.equals("EL6B", p1.EL6B(L6()).name);
}
