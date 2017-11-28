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
  doLoop(true);
  stringInterpolation(0);
  stringInterpolation(null);
  boxing();
  captureTwice();
  var c = new Class();
  equals(c, 0);
  c.property1 = 1;
  c.property2 = 2;
  equals(c, null);
  c.captureTwice();
  switchStatement(1);
  switchStatement(0);
  switchStatementConst(const Const(0));
  switchStatementConst(const Const(1));
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

doLoop(local) {
  do {
    print(local);
  } while (local);
}

stringInterpolation(a) {
  // TODO(johnniwinther): Handle interpolation of `a` itself.
  print('${a()}');
}

boxing() {
  var b = 0;
  () {
    b = 2;
  }();
  return b;
}

captureTwice() {
  var b = 0;
  () {
    return b + b;
  }();
  return b;
}

class Class {
  var property1;
  var property2;

  captureTwice() {
    return () {
      return property1 == property2;
    };
  }
}

equals(a, b) {
  return a.property1 == b;
}

switchStatement(a) {
  switch (a) {
    case 0:
      return 1;
    case 1:
      return 2;
    case 2:
      return 3;
  }
}

class Const {
  final int value;

  const Const(this.value);
}

switchStatementConst(a) {
  switch (a) {
    case const Const(0):
      return 1;
    case const Const(2):
      return 2;
    case const Const(2):
      return 3;
  }
}
