// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:explicit=[A<int>],needsArgs*/
class A<T> {}

class B extends A<int> {}

main() {
  B() is A<int>;
}
