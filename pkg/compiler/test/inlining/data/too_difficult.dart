// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  asyncMethod();
  asyncStarMethod();
  syncStarMethod();
  localFunction();
  anonymousFunction();
  tryCatch();
  tryFinally();
  tryWithRethrow();
  forLoop();
  forInLoop();
  whileLoop();
  doLoop();

  multipleReturns();
  codeAfterReturn();
  multipleThrows();
  returnAndThrow();

  throwClosure();
  returnClosure();
  closureInInitializer();
}

/*member: _multipleReturns:code after return*/
_multipleReturns(c) {
  if (c)
    return;
  else
    return;
}

/*member: multipleReturns:[]*/
@pragma('dart2js:noInline')
multipleReturns() {
  _multipleReturns(true);
  _multipleReturns(false);
}

/*member: _codeAfterReturn:code after return*/
_codeAfterReturn(c) {
  if (c) return;
  print(c);
}

/*member: codeAfterReturn:[]*/
@pragma('dart2js:noInline')
codeAfterReturn() {
  _codeAfterReturn(true);
  _codeAfterReturn(false);
}

/*member: _multipleThrows:[]*/
_multipleThrows(c) {
  if (c)
    throw '';
  else
    throw '';
}

/*member: multipleThrows:[]*/
@pragma('dart2js:noInline')
multipleThrows() {
  _multipleThrows(true);
  _multipleThrows(false);
}

/*member: _returnAndThrow:code after return*/
_returnAndThrow(c) {
  if (c)
    return;
  else
    throw '';
}

/*member: returnAndThrow:[]*/
@pragma('dart2js:noInline')
returnAndThrow() {
  _returnAndThrow(true);
  _returnAndThrow(false);
}

/*member: asyncMethod:async/await*/
asyncMethod() async {}

/*member: asyncStarMethod:async/await*/
asyncStarMethod() async* {}

/*member: syncStarMethod:async/await*/
syncStarMethod() sync* {}

/*member: localFunction:closure*/
localFunction() {
  // ignore: UNUSED_ELEMENT
  /*[]*/ local() {}
}

/*member: anonymousFunction:closure*/
anonymousFunction() {
  /*[]*/ () {};
}

/*member: tryCatch:try*/
tryCatch() {
  try {} catch (e) {}
}

/*member: tryFinally:try*/
tryFinally() {
  try {} finally {}
}

/*member: tryWithRethrow:try*/
tryWithRethrow() {
  try {} catch (e) {
    rethrow;
  }
}

/*member: forLoop:loop*/
forLoop() {
  for (int i = 0; i < 10; i++) {
    print(i);
  }
}

/*member: forInLoop:loop*/
forInLoop() {
  for (var e in [0, 1, 2]) {
    print(e);
  }
}

/*member: whileLoop:loop*/
whileLoop() {
  int i = 0;
  while (i < 10) {
    print(i);
    i++;
  }
}

/*member: doLoop:loop*/
doLoop() {
  int i = 0;
  do {
    print(i);
    i++;
  } while (i < 10);
}

/*member: returnClosure:closure*/
returnClosure() {
  return /*[]*/ () {};
}

/*member: throwClosure:closure*/
throwClosure() {
  throw /*[]*/ () {};
}

class Class1 {
  var f;

  /*member: Class1.:closure*/
  Class1() : f = (/*[]*/ () {}) {
    print(f);
  }
}

/*member: closureInInitializer:[]*/
@pragma('dart2js:noInline')
closureInInitializer() {
  new Class1();
}
