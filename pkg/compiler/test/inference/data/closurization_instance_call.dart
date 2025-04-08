// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on instance method tear-off with a non synthesized
// '.call' method in the closed world.
////////////////////////////////////////////////////////////////////////////////

/*member: Class.:[exact=Class|powerset=0]*/
class Class {
  /*member: Class.call:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  call() => true;

  /*member: Class.method:[exact=JSUInt31|powerset=0]*/
  method() => 42;
}

/*member: closurizedCallToString:[exact=JSString|powerset=0]*/
closurizedCallToString() {
  var c = Class();
  c. /*invoke: [exact=Class|powerset=0]*/ call(); // Make `Class.call` live.
  var local = c. /*[exact=Class|powerset=0]*/ method;
  local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
}
