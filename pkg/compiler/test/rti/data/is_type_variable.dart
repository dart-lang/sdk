// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:direct,explicit=[A.T*],needsArgs*/
class A<T> {
  m(T t) => t is T;
}

main() {
  new A<int>().m(0);
}
