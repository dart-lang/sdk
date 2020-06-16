// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 31333.

import 'package:expect/expect.dart';

main() {
  Expect.throws(() => method() + 42, (e) => e is NoSuchMethodError);
}

method() {
  var local = ({foo}) => 42;
  local(foo: 1).isEven;
  // Global type inference wrongfully refines `local` to have type JSInt.
  return local;
}
