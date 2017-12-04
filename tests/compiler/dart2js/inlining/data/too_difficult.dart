// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[]*/
main() {
  multipleReturns(true);
  codeAfterReturn(true);
  multipleThrows(true);
  codeAfterThrow(true);
  throwAndReturn(true);
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
}

/*element: multipleReturns:[]*/
multipleReturns(c) {
  if (c)
    return;
  else
    return;
}

/*element: codeAfterReturn:[]*/
codeAfterReturn(c) {
  if (c) return;
  print(c);
}

/*element: multipleThrows:[]*/
multipleThrows(c) {
  if (c)
    throw '';
  else
    throw '';
}

/*element: codeAfterThrow:[]*/
codeAfterThrow(c) {
  if (c) throw '';
  print(c);
}

/*element: throwAndReturn:[]*/
throwAndReturn(c) {
  if (c)
    throw '';
  else
    return;
}

/*element: asyncMethod:[]*/
asyncMethod() async {}

/*element: asyncStarMethod:[]*/
asyncStarMethod() async* {}

/*element: syncStarMethod:[]*/
syncStarMethod() sync* {}

/*element: localFunction:[]*/
localFunction() {
  // ignore: UNUSED_ELEMENT
  /*[]*/ local() {}
}

/*element: anonymousFunction:[]*/
anonymousFunction() {
  /*[]*/ () {};
}

/*element: tryCatch:[]*/
tryCatch() {
  try {} catch (e) {}
}

/*element: tryFinally:[]*/
tryFinally() {
  try {} catch (e) {}
}

/*element: tryWithRethrow:[]*/
tryWithRethrow() {
  try {} catch (e) {
    rethrow;
  }
}

/*element: forLoop:[]*/
forLoop() {
  for (int i = 0; i < 10; i++) {
    print(i);
  }
}

/*element: forInLoop:[]*/
forInLoop() {
  for (var e in [0, 1, 2]) {
    print(e);
  }
}

/*element: whileLoop:[]*/
whileLoop() {
  int i = 0;
  while (i < 10) {
    print(i);
    i++;
  }
}

/*element: doLoop:[]*/
doLoop() {
  int i = 0;
  do {
    print(i);
    i++;
  } while (i < 10);
}
