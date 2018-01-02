// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/dont_inline_deferred_global_lib.dart' deferred as lib;

/*element: main:OutputUnit(main, {})*/
void main() {
  lib.loadLibrary().then((_) {
    print(lib.finalVar);
    print(lib.globalVar);
    lib.globalVar = "foobar";
    print(lib.globalVar);
  });
}
