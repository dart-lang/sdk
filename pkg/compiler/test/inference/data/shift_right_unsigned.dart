// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  g1 = -1;
  g1 = 2;
  test1();
  test2();
  test3();
  test4();
}

/*member: g1:[subclass=JSInt|powerset={I}{O}]*/
int g1 = 0;

/*member: test1:[exact=JSUInt31|powerset={I}{O}]*/
test1() {
  int a = 1234;
  int b = 2;
  return a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ >>> b;
}

/*member: test2:[subclass=JSUInt32|powerset={I}{O}]*/
test2() {
  return g1 /*invoke: [subclass=JSInt|powerset={I}{O}]*/ >>> g1;
}

/*member: test3:[subclass=JSUInt32|powerset={I}{O}]*/
test3() {
  return g1 /*invoke: [subclass=JSInt|powerset={I}{O}]*/ >>> 1;
}

/*member: test4:[exact=JSUInt31|powerset={I}{O}]*/
test4() {
  return 10 /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ >>> g1;
}
