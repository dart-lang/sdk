// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

var field;

/*member: anonymousClosureUnused:SideEffects(reads nothing; writes nothing)*/
anonymousClosureUnused() {
  /*SideEffects(reads static; writes nothing)*/
  () => field;
}

/*member: anonymousClosureCalled:SideEffects(reads anything; writes anything)*/
anonymousClosureCalled() {
  var localFunction = /*SideEffects(reads static; writes nothing)*/ () => field;
  return localFunction();
}

/*member: localFunctionUnused:SideEffects(reads nothing; writes nothing)*/
localFunctionUnused() {
  // ignore: UNUSED_ELEMENT
  /*SideEffects(reads static; writes nothing)*/ localFunction() => field;
}

/*member: localFunctionCalled:SideEffects(reads static; writes nothing)*/
localFunctionCalled() {
  /*SideEffects(reads static; writes nothing)*/ localFunction() => field;
  return localFunction();
}

/*member: main:SideEffects(reads anything; writes anything)*/
main() {
  anonymousClosureUnused();
  anonymousClosureCalled();
  localFunctionUnused();
  localFunctionCalled();
}
