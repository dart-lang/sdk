// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/*@testedFeatures=inference*/
library test;

typedef int FunctionReturningInt();

main() {
  num f() => 0;
  if (f is FunctionReturningInt) {
    f;
  }
}
