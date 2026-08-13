// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

T run<T>(T f()) {
  print("running");
  var t = f();
  print("done running");
  return t;
}

void printRunning() {
  print("running");
}

var y = /*info:USE_OF_VOID_RESULT*/ run(printRunning);

main() {}
