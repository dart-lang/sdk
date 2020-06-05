// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import '../libs/deferred_lib1.dart';
import '../libs/deferred_lib2.dart' deferred as lib2;

main() async {
  C1.value;
  print(const C(4));
  () => print(const C(5));
  await lib2.loadLibrary();
  lib2.C2;
  lib2.C3;
  lib2.C4;
  lib2.C5;
  lib2.C6;
  lib2.C7.value;
}
