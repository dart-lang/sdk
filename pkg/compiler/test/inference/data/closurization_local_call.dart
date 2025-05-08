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

/*member: Class.:[exact=Class|powerset={N}{O}]*/
class Class {
  /*member: Class.call:Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O})*/
  call() => true;
}

/*member: closurizedCallToString:[exact=JSString|powerset={I}{O}]*/
closurizedCallToString() {
  var c = Class();
  c. /*invoke: [exact=Class|powerset={N}{O}]*/ call(); // Make `Class.call` live.
  var local = /*[exact=JSUInt31|powerset={I}{O}]*/ () => 42;
  local. /*invoke: [subclass=Closure|powerset={N}{O}]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset={N}{O}]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset={N}{O}]*/ toString();
}
