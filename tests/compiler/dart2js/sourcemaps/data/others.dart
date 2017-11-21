// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test file for testing source mappings of various expression and statements.

main() {
  throwStatement();
  whileLoop(true);
  forLoop(false);
  forInLoop([1]);
  forInLoop([1, 2]);
  forInLoopEmpty([]);
  forInLoopNull(null);
  stringInterpolation(0);
  stringInterpolation(null);
}

throwStatement() {
  throw 'foo';
}

whileLoop(local) {
  while (local) {
    print(local);
  }
}

forLoop(local) {
  for (; local;) {
    print(local);
  }
}

forInLoop(local) {
  for (var e in local) {
    print(e);
  }
}

forInLoopEmpty(local) {
  for (var e in local) {
    print(e);
  }
}

forInLoopNull(local) {
  for (var e in local) {
    print(e);
  }
}

stringInterpolation(a) {
  // TODO(johnniwinther): Handle interpolation of `a` itself.
  print('${a()}');
}
