// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:[exact=JSUInt31|powerset={I}{O}{N}]*/
// Called only via [foo] with a small integer.
method(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) {
  return a;
}

/*member: foo:[subclass=Closure|powerset={N}{O}{N}]*/
var foo = method;

/*member: returnInt:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
returnInt() {
  return foo(54);
}

/*member: main:[null|powerset={null}]*/
main() {
  returnInt();
}
