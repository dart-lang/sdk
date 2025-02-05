// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';
import 'package:expect/expect.dart';

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  final e = Exported();
  final i1 = Interface.v1();
  final i2 = Interface.v2();

  Expect.equals(3, e.method3());
  Expect.equals(2, i1.method1());
  Expect.equals(4, i2.method1());
  // TODO(sigmund): expand test to use records, which currently fails in AOT.
  return Triple(e, i1, i2);
}
