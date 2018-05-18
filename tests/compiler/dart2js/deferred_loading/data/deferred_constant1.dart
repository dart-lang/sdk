// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_constant1_lib1.dart';
import '../libs/deferred_constant1_lib2.dart' deferred as lib2;

/*element: main:OutputUnit(main, {})*/
main() async {
  C1.value;
  print(const C(4));
  /*OutputUnit(main, {})*/ () => print(const C(5));
  await lib2.loadLibrary();
  lib2.C2.value;
  lib2.C3.value;
  lib2.C4.value;
  lib2.C5.value;
  lib2.C6;
  lib2.C7.value;
}
