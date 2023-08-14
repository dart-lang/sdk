// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1(var a) {
  yield null;
  yield a;
  yield a();
  yield 1;
}

method2() {
  yield* [1];
}

method3() async {
  yield 1;
}

method4() async {
  yield [1];
}