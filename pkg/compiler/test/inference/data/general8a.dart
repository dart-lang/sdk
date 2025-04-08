// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
foo(/*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ x) {
  return x;
}

/*member: bar:[null|powerset=1]*/
bar(/*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*member: main:[null|powerset=1]*/
main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
