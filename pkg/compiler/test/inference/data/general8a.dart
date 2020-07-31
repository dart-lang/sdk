// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: foo:Value([exact=JSBool], value: false)*/
foo(/*Value([exact=JSBool], value: false)*/ x) {
  return x;
}

/*member: bar:[null]*/
bar(/*Value([exact=JSBool], value: false)*/ x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*member: main:[null]*/
main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
