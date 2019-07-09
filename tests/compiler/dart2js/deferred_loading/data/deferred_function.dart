// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that loading of a library (with top-level functions only) can
// be deferred.

import '../libs/deferred_function_lib.dart' deferred as lib;

/*strong.member: readFoo:OutputUnit(main, {})*/
/*strongConst.member: readFoo:
 OutputUnit(main, {}),
 constants=[FunctionConstant(foo)=OutputUnit(1, {lib})]
*/
readFoo() {
  return lib.foo;
}

/*member: main:OutputUnit(main, {})*/
main() {
  lib.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
    lib.foo('b');
    readFoo();
  });
}
