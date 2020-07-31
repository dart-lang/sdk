// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on static method tear-off.
////////////////////////////////////////////////////////////////////////////////

/*member: method:[exact=JSUInt31]*/
method() => 42;

/*member: closurizedCallToString:[exact=JSString]*/
closurizedCallToString() {
  var local = method;
  local. /*invoke: [subclass=Closure]*/ toString();
  local();
  local. /*invoke: [subclass=Closure]*/ toString();
  local.call();
  return local. /*invoke: [subclass=Closure]*/ toString();
}
