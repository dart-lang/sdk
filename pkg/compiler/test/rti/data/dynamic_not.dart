// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {
  /*member: A.instanceMethod:*/
  instanceMethod<T>(t) => t;
}

main() {
  var a = new A();
  a.instanceMethod<int>(0);
}
