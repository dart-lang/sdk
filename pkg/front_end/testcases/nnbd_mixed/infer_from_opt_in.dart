// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'infer_from_opt_in_lib.dart';

reify<T>(T arg) => T;

main() {
  Foo x = new Foo();
  var y = new Foo();
  var z = () => createFoo();
  callback((x) => x);
  print(reify(x));
  print(reify(y));
  print(reify(z));
}
