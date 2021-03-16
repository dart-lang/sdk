// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib.dart' deferred as lib;

main() async {
  await lib.loadLibrary();

  // inferred return-type in closures:
  lib.B f1() => lib.B(); //# 01: compile-time error
  var f2 = () => lib.B(); // no error, but f1 has inferred type: () -> d.B

  // inferred type-arguments
  lib.list = <lib.B>[]; //# 02: compile-time error
  lib.list = []; // no error, but type parameter was injected here
  lib.list = lib.list.map((x) => x.value!).toList(); // no error, type parameter inferred on closure and map<T>.
}
