// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that loading of a library (with top-level functions only) can
// be deferred.

import '../libs/deferred_function_lib.dart' deferred as lib;

/*element: isError:OutputUnit(main, {})*/
bool isError(e) => e is Error;

/*element: readFoo:OutputUnit(main, {})*/
readFoo() {
  return lib.foo;
}

/*element: main:OutputUnit(main, {})*/
main() {
  lib.loadLibrary().then((_) {
    lib.foo('b');
    readFoo();
  });
}
