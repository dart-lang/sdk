// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
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

/*element: _multipleReturns:code after return*/
_multipleReturns(c) {
  if (c)
    return;
  else
    return;
}

/*element: multipleReturns:[]*/
@NoInline()
multipleReturns() {
  _multipleReturns(true);
  _multipleReturns(false);
}

/*element: _codeAfterReturn:code after return*/
_codeAfterReturn(c) {
  if (c) return;
  print(c);
}

/*element: codeAfterReturn:[]*/
@NoInline()
codeAfterReturn() {
  _codeAfterReturn(true);
  _codeAfterReturn(false);
}

/*element: _multipleThrows:[]*/
_multipleThrows(c) {
  if (c)
    throw '';
  else
    throw '';
}

/*element: multipleThrows:[]*/
@NoInline()
multipleThrows() {
  _multipleThrows(true);
  _multipleThrows(false);
}

/*element: _returnAndThrow:code after return*/
_returnAndThrow(c) {
  if (c)
    return;
  else
    throw '';
}

/*element: returnAndThrow:[]*/
@NoInline()
returnAndThrow() {
  _returnAndThrow(true);
  _returnAndThrow(false);
}

/*element: asyncMethod:async/await*/
asyncMethod() async {}

/*element: asyncStarMethod:async/await*/
asyncStarMethod() async* {}

/*element: syncStarMethod:async/await*/
syncStarMethod() sync* {}

/*element: localFunction:closure*/
localFunction() {
  // ignore: UNUSED_ELEMENT
  /*[]*/ local() {}
}

/*element: anonymousFunction:closure*/
anonymousFunction() {
  /*[]*/ () {};
}

/*element: tryCatch:try*/
tryCatch() {
  try {} catch (e) {}
}

/*element: tryFinally:try*/
tryFinally() {
  try {} finally {}
}

/*element: tryWithRethrow:try*/
tryWithRethrow() {
  try {} catch (e) {
    rethrow;
  }
}

/*element: forLoop:loop*/
forLoop() {
  for (int i = 0; i < 10; i++) {
    print(i);
  }
}

/*element: forInLoop:loop*/
forInLoop() {
  for (var e in [0, 1, 2]) {
    print(e);
  }
}

/*element: whileLoop:loop*/
whileLoop() {
  int i = 0;
  while (i < 10) {
    print(i);
    i++;
  }
}

/*element: doLoop:loop*/
doLoop() {
  int i = 0;
  do {
    print(i);
    i++;
  } while (i < 10);
}

/*element: returnClosure:closure*/
returnClosure() {
  return /*[]*/ () {};
}

/*element: throwClosure:closure*/
throwClosure() {
  throw /*[]*/ () {};
}

class Class1 {
  var f;

  /*element: Class1.:closure*/
  Class1() : f = (/*[]*/ () {}) {
    print(f);
  }
}

/*element: closureInInitializer:[]*/
@NoInline()
closureInInitializer() {
  new Class1();
}
