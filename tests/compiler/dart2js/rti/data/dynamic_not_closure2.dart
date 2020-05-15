// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {
  /*member: A.instanceMethod:deps=[local]*/
  instanceMethod<T>(t) => t;
}

main() {
  local<T>(t) {
    var a = new A();
    a.instanceMethod<T>(t);
  }

  local<int>(0);
}
