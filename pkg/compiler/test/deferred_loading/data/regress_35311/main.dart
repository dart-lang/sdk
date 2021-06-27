// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*library: 
 a_pre_fragments=[p1: {units: [1{lib}], usedBy: [], needs: []}],
 b_finalized_fragments=[f1: [1{lib}]],
 c_steps=[lib=(f1)]
*/
import 'lib.dart' deferred as lib;

/*member: main:member_unit=main{}*/
main() async {
  await lib.loadLibrary();

  // inferred return-type in closures:
  // lib.B f1() => lib.B(); // Compile time error(see tests/web)
  var f2 = /*closure_unit=main{}*/ () =>
      lib.B(); // no compile error, but f1 has inferred type: () -> d.B

  // inferred type-arguments
  // lib.list = <lib.B>[]; // Compile time error(see tests/web)
  lib.list = []; // no error, but type parameter was injected here
  lib.list = lib.list
      .map(/*closure_unit=main{}*/ (x) => x.value)
      .toList(); // no Compile error, type parameter inferred on closure and map<T>.
}
