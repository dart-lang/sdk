// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_typed_map_lib1.dart' deferred as lib;

/*element: main:OutputUnit(main, {})*/
main() async {
  await lib.loadLibrary();
  print(lib.table[1]);
}
