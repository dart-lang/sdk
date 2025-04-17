// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:[exact=JSBool|powerset={I}]*/
foo(/*[exact=JSUInt31|powerset={I}]*/ x) {
  if (x /*invoke: [exact=JSUInt31|powerset={I}]*/ > 3) return true;
  return false;
}

/*member: bar:[null|powerset={null}]*/
bar(/*[exact=JSBool|powerset={I}]*/ x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*member: main:[null|powerset={null}]*/
main() {
  bar(foo(5));
  bar(foo(6));
}
