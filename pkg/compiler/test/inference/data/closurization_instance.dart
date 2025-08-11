// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on instance method tear-off.
////////////////////////////////////////////////////////////////////////////////

/*member: Class.:[exact=Class|powerset={N}{O}{N}]*/
class Class {
  /*member: Class.method:[exact=JSUInt31|powerset={I}{O}{N}]*/
  method() => 42;
}

/*member: closurizedCallToString:[exact=JSString|powerset={I}{O}{I}]*/
closurizedCallToString() {
  var c = Class();
  var local = c. /*[exact=Class|powerset={N}{O}{N}]*/ method;
  local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
}
