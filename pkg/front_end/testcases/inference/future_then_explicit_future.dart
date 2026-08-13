// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import "dart:async";

m1(Future<int> f) {
  var x = f.then<Future<List<int>>>(
    /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/
    (x) => [],
  );
  Future<List<int>> y = x;
}

m2(Future<int> f) {
  var x = f.then<List<int>>((x) => []);
  Future<List<int>> y = x;
}

main() {}
