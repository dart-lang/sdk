// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

Function _foo<T>(FutureOr<T> f()) {
  return (() async {
    await f();
  });
}

main() async {
  var x = 0;
  _foo<int>(() => x = 1)();
  Expect.equals(1, x);
}
