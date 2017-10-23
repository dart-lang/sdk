// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var field;

/*element: anonymousClosureUnused:Depends on nothing, Changes nothing.*/
anonymousClosureUnused() {
  /*Depends on static store, Changes nothing.*/
  () => field;
}

/*element: anonymousClosureCalled:Depends on [] field store static store, Changes [] field static.*/
anonymousClosureCalled() {
  var localFunction = /*Depends on static store, Changes nothing.*/ () => field;
  return localFunction();
}

/*element: localFunctionUnused:Depends on nothing, Changes nothing.*/
localFunctionUnused() {
  // ignore: UNUSED_ELEMENT
  /*Depends on static store, Changes nothing.*/ localFunction() => field;
}

/*element: localFunctionCalled:Depends on static store, Changes nothing.*/
localFunctionCalled() {
  /*Depends on static store, Changes nothing.*/ localFunction() => field;
  return localFunction();
}

/*element: main:Depends on [] field store static store, Changes [] field static.*/
main() {
  anonymousClosureUnused();
  anonymousClosureCalled();
  localFunctionUnused();
  localFunctionCalled();
}
