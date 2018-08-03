// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T run<T>(T f()) {
  print("running");
  var /*@type=run::T*/ t = f();
  print("done running");
  return t;
}

void printRunning() {
  print("running");
}

var /*@topType=dynamic*/ x = run<dynamic>(printRunning);

main() {
  void printRunning() {
    print("running");
  }

  var /*@type=dynamic*/ x = run<dynamic>(printRunning);
  var /*@type=void*/ y = /*info:USE_OF_VOID_RESULT*/ /*@typeArgs=void*/ run(
      printRunning);
  x = 123;
  x = 'hi';
  y = /*error:INVALID_ASSIGNMENT*/ 123;
  y = /*error:INVALID_ASSIGNMENT*/ 'hi';
}
