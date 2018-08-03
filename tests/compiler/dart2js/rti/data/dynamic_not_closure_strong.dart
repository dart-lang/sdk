// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*element: A.instanceMethod:*/
  instanceMethod<T>(t) => t;
}

main() {
  local() {
    var a = new A();
    a.instanceMethod<int>(0);
  }

  local();
}
