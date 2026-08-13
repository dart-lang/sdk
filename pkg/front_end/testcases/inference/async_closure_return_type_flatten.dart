// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

Future<int> futureInt = new Future<int>.value(0);
var f = () => futureInt;
var g = () async => futureInt;

main() {
  f;
  g;
}
