// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T run<T>(T f()) {
  print("running");
  var /*@type=T*/ t = /*@promotedType=none*/ f();
  print("done running");
  return /*@promotedType=none*/ t;
}

void printRunning() {
  print("running");
}

var /*@topType=dynamic*/ x = run<dynamic>(printRunning);
var /*@topType=dynamic*/ y = /*info:USE_OF_VOID_RESULT, error:TOP_LEVEL_TYPE_ARGUMENTS*/ run(
    printRunning);

main() {
  void printRunning() {
    print("running");
  }

  var /*@type=dynamic*/ x = run<dynamic>(printRunning);
  var /*@type=void*/ y = /*info:USE_OF_VOID_RESULT*/ run(printRunning);
  x = 123;
  x = 'hi';
  y = /*error:INVALID_ASSIGNMENT*/ 123;
  y = /*error:INVALID_ASSIGNMENT*/ 'hi';
}
