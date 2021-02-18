// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:async';

ok<T extends FutureOr<num>>(T t) {}
error<T extends FutureOr<int>>(T t) {}

bar(bool condition) {
  FutureOr<int> x = null;
  num n = 1;
  var z = condition ? x : n;

  ok(z); // Ok.
  error(z); // Error.
}

main() {}
