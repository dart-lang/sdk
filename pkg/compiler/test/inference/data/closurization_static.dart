// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on static method tear-off.
////////////////////////////////////////////////////////////////////////////////

/*member: method:[exact=JSUInt31|powerset=0]*/
method() => 42;

/*member: closurizedCallToString:[exact=JSString|powerset=0]*/
closurizedCallToString() {
  var local = method;
  local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
  local();
  local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
}
