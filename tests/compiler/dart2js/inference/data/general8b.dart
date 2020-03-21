// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: foo:[exact=JSBool]*/
foo(/*[exact=JSUInt31]*/ x) {
  if (x /*invoke: [exact=JSUInt31]*/ > 3) return true;
  return false;
}

/*member: bar:[null]*/
bar(/*[exact=JSBool]*/ x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*member: main:[null]*/ main() {
  bar(foo(5));
  bar(foo(6));
}
