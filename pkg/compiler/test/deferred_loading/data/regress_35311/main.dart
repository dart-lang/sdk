// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib.dart' deferred as lib;

/*member: main:OutputUnit(main, {})*/
main() async {
  await lib.loadLibrary();

  // inferred return-type in closures:
  // lib.B f1() => lib.B(); // Compile time error(see tests/dart2js)
  var f2 = /*OutputUnit(main, {})*/ () =>
      lib.B(); // no compile error, but f1 has inferred type: () -> d.B

  // inferred type-arguments
  // lib.list = <lib.B>[]; // Compile time error(see tests/dart2js)
  lib.list = []; // no error, but type parameter was injected here
  lib.list = lib.list
      .map(/*OutputUnit(main, {})*/ (x) => x.value)
      .toList(); // no Compile error, type parameter inferred on closure and map<T>.
}
