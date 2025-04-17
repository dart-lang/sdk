// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on a local variable with a non synthesized '.call'
// method in the closed world.
////////////////////////////////////////////////////////////////////////////////

/*member: Class.:[exact=Class|powerset={N}]*/
class Class {
  /*member: Class.call:Value([exact=JSBool|powerset={I}], value: true, powerset: {I})*/
  call() => true;
}

/*member: closurizedCallToString:[exact=JSString|powerset={I}]*/
closurizedCallToString() {
  var c = Class();
  c. /*invoke: [exact=Class|powerset={N}]*/ call(); // Make `Class.call` live.
  var local = /*[exact=JSUInt31|powerset={I}]*/ () => 42;
  local. /*invoke: [subclass=Closure|powerset={N}]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset={N}]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset={N}]*/ toString();
}
