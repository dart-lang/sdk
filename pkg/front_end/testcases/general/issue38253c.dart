// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var a = () {
  g f1() {}
  g f2() async {}
  int f3() {}
  Future<int> f4() async {}
};

var b = (f) async => await f;

var c = (f) => f;

main() {}
