// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test file for testing source mappings of various expression and statements.

main() {
  throwStatement();
  whileLoop(true);
  forLoop(false);
  forInLoop([1]);
  forInLoop([1, 2]);
  forInLoopBreak([1]);
  forInLoopBreak([1, 2]);
  forInLoopContinue([1]);
  forInLoopContinue([1, 2]);
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
  equals2(c, null);
  equals2(c, c);
  var c2 = new Class2();
  c2.field1 = new Class2();
  c2.field2 = new Class2();
  c2 == c2.field1;
  new Class3(87);
  switchStatement(1);
  switchStatement(0);
  switchStatementConst(const Const(0));
  switchStatementConst(const Const(1));
  switchStatementBreak(0);
  switchStatementBreak(1);
  switchStatementBreakContinue(0);
  switchStatementBreakContinue(1);
  isInt(null);
  isInt(0);
  isDouble(null);
  isDouble(0.5);
  isBool(null);
  isBool(true);
  isString(null);
  isString('');
  asString(0);
  asString('');
  isList([]);
  isList(null);
  isListOfString(<String>[]);
  isListOfString(<int>[]);
  tryCatch();
  tryOnCatch();
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

forInLoopBreak(local) {
  for (var e in local) {
    if (e == 1) {
      break;
    }
    print(e);
  }
}

forInLoopContinue(local) {
  for (var e in local) {
    if (e == 1) {
      continue;
    }
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

equals2(a, b) {
  return b != null && a.property1 == b.property1 && a.property2 == b.property2;
}

class Class2 {
  var field1;
  var field2;

  operator ==(other) {
    return other != null && field1 == other.field1 && field2 == other.field2;
  }
}

class Class3 {
  var field1;
  var field2;

  Class3(this.field1) {
    this.field2 = 42;
  }
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

switchStatementBreak(a) {
  switch (a) {
    case 0:
      break;
    case 1:
      return 2;
    case 2:
      break;
  }
}

switchStatementBreakContinue(a) {
  switch (a) {
    case 0:
      break;
    label:
    case 1:
      return 2;
    case 2:
      continue label;
  }
}

isInt(e) {
  e = e is int;
  print(e);
  return e;
}

isDouble(e) {
  e = e is double;
  print(e);
  return e;
}

isBool(e) {
  e = e is bool;
  print(e);
  return e;
}

isString(e) {
  e = e is String;
  print(e);
  return e;
}

isList(e) {
  e = e is List;
  print(e);
  return e;
}

isListOfString(e) {
  e = e is List<String>;
  print(e);
  return e;
}

asString(e) {
  e = e as String;
  print(e);
  return e;
}

tryCatch() {
  try {
    throw '';
  } catch (e) {
    print(e);
  }
}

tryOnCatch() {
  try {
    throw '';
  } on String catch (e) {
    print(e);
  } on int catch (e) {
    print(e);
  }
}
