// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on a local variable with a non synthesized '.call'
// method in the closed world.
////////////////////////////////////////////////////////////////////////////////

/*element: Class.:[exact=Class]*/
class Class {
  /*element: Class.call:Value([exact=JSBool], value: true)*/
  call() => true;
}

// TODO(johnniwinther): Fix the refined type. Missing call methods in the closed
// world leads to concluding [exact=Class].
/*ast.element: closurizedCallToString:[exact=JSString]*/
/*kernel.element: closurizedCallToString:[exact=JSString]*/
/*strong.element: closurizedCallToString:[empty]*/
closurizedCallToString() {
  var c = new Class();
  c.call(); // Make `Class.call` live.
  var local = /*[exact=JSUInt31]*/ () => 42;
  local
      .
      /*ast.invoke: [subtype=Function]*/
      /*kernel.invoke: [subtype=Function]*/
      /*strong.invoke: [subclass=Closure]*/
      toString();
  local();
  local
      .
      /*ast.invoke: [exact=Class]*/
      /*kernel.invoke: [exact=Class]*/
      /*strong.invoke: [empty]*/
      toString();
  local.call();
  return local
      .
      /*ast.invoke: [exact=Class]*/
      /*kernel.invoke: [exact=Class]*/
      /*strong.invoke: [empty]*/
      toString();
}
