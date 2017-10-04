// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  namedLocalFunctionInvoke();
  unnamedLocalFunctionInvoke();
  namedLocalFunctionGet();
  recursiveLocalFunction();
}

/*element: namedLocalFunctionInvoke:[exact=JSUInt31]*/
namedLocalFunctionInvoke() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local();
}

/*element: unnamedLocalFunctionInvoke:[null|subclass=Object]*/
unnamedLocalFunctionInvoke() {
  var local = /*[exact=JSUInt31]*/ () => 0;
  return local();
}

/*element: namedLocalFunctionGet:[subclass=Closure]*/
namedLocalFunctionGet() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local;
}

/*element: recursiveLocalFunction:[subclass=Closure]*/
recursiveLocalFunction() {
  /*[subclass=Closure]*/ local() => local;
  return local();
}
