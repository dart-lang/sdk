// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on static method tear-off with a non synthesized
// '.call' method in the closed world.
////////////////////////////////////////////////////////////////////////////////

/*member: method:[exact=JSUInt31]*/
method() => 42;

/*member: Class.:[exact=Class]*/
class Class {
  /*member: Class.call:Value([exact=JSBool], value: true)*/
  call() => true;
}

/*member: closurizedCallToString:[exact=JSString]*/
closurizedCallToString() {
  var c = new Class();
  c. /*invoke: [null|exact=Class]*/ call(); // Make `Class.call` live.
  var local = method;
  local. /*invoke: [subclass=Closure]*/ toString();
  local();
  local. /*invoke: [subclass=Closure]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure]*/ toString();
}
