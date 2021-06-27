// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'liba.dart' deferred as liba;
import 'libb.dart' deferred as libb;
import 'lib_shared.dart';

main() async {
  var f = () => libb.C();
  Expect.isTrue(f is C_Parent Function());
  await liba.loadLibrary();
  await libb.loadLibrary();

  Expect.isTrue(liba.isA(libb.createA()));
  print(libb.createA());
  print(libb.createC());
  Expect.isTrue(libb.isB(B()));
  Expect.isTrue(liba.isD(libb.createE()));
  Expect.isFalse(libb.isFWithUnused(null as dynamic));
}
