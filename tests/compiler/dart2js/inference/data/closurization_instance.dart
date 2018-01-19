// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  closurizedCallToString();
}

////////////////////////////////////////////////////////////////////////////////
// Implicit/explicit .call on instance method tear-off.
////////////////////////////////////////////////////////////////////////////////

/*element: Class.:[exact=Class]*/
class Class {
  /*element: Class.method:[exact=JSUInt31]*/
  method() => 42;
}

// TODO(johnniwinther): Fix the refined type. Missing call methods in the closed
// world leads to concluding [empty].
/*element: closurizedCallToString:[empty]*/
closurizedCallToString() {
  var c = new Class();
  var local = c. /*[exact=Class]*/ method;
  local. /*invoke: [subclass=Closure]*/ toString();
  local();
  local
      . /*invoke: [empty]*/
      toString();
  local.call();
  return local
      . /*invoke: [empty]*/
      toString();
}
