// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

int f<T>(T a) => null;

typedef int F<R>(R a);

/*member: B.:hasThis*/
class B<S> {
  /*member: B.method:hasThis*/
  method() {
    return
        /*spec.fields=[this],free=[this],hasThis*/
        /*prod.hasThis*/
        () {
      F<S> c = f;
      return c;
    };
  }
}

main() {
  new B().method();
}
