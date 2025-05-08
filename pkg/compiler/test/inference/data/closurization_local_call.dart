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

/*member: Class.:[exact=Class|powerset={N}{O}{N}]*/
class Class {
  /*member: Class.call:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  call() => true;
}

/*member: closurizedCallToString:[exact=JSString|powerset={I}{O}{I}]*/
closurizedCallToString() {
  var c = Class();
  c. /*invoke: [exact=Class|powerset={N}{O}{N}]*/ call(); // Make `Class.call` live.
  var local = /*[exact=JSUInt31|powerset={I}{O}{N}]*/ () => 42;
  local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
}
