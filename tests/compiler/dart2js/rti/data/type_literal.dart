// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:needsArgs,exp*/
class A<T> {
  m() => T;
}

main() {
  new A<int>().m();
}
