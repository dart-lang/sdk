// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{lib}], usedBy: [], needs: []}],
 steps=[lib=(f1)]
*/

// @dart = 2.7

// Test that loading of a library (with top-level functions only) can
// be deferred.

import 'lib.dart' deferred as lib;

/*member: readFoo:
 constants=[FunctionConstant(foo)=1{lib}],
 member_unit=main{}
*/
readFoo() {
  return lib.foo;
}

/*member: main:member_unit=main{}*/
main() {
  lib.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    lib.foo('b');
    readFoo();
  });
}
