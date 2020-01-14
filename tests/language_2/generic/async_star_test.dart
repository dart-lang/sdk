// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:async';

Stream<T> foo<T>(T x) async* {
  for (int i = 0; i < 3; i++) {
    yield x;
  }
}

main() async {
  await for (var x in foo<int>(1)) {
    Expect.equals(1, x);
  }
}
