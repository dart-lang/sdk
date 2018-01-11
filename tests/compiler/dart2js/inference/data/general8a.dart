// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: foo:Value([exact=JSBool], value: false)*/
foo(/*Value([exact=JSBool], value: false)*/ x) {
  return x;
}

/*element: bar:[null]*/
bar(/*Value([exact=JSBool], value: false)*/ x) {
  if (x) {
    print("aaa");
  } else {
    print("bbb");
  }
}

/*element: main:[null]*/
main() {
  bar(foo(false));
  bar(foo(foo(false)));
}
