// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var field;

/*element: anonymousClosureUnused:Reads nothing; writes nothing.*/
anonymousClosureUnused() {
  /*Reads static; writes nothing.*/
  () => field;
}

/*element: anonymousClosureCalled:Reads anything; writes anything.*/
anonymousClosureCalled() {
  var localFunction = /*Reads static; writes nothing.*/ () => field;
  return localFunction();
}

/*element: localFunctionUnused:Reads nothing; writes nothing.*/
localFunctionUnused() {
  // ignore: UNUSED_ELEMENT
  /*Reads static; writes nothing.*/ localFunction() => field;
}

/*element: localFunctionCalled:Reads static; writes nothing.*/
localFunctionCalled() {
  /*Reads static; writes nothing.*/ localFunction() => field;
  return localFunction();
}

/*element: main:Reads anything; writes anything.*/
main() {
  anonymousClosureUnused();
  anonymousClosureCalled();
  localFunctionUnused();
  localFunctionCalled();
}
