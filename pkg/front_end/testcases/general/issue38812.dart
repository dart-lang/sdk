// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef G<X> = void Function();

class A<X extends G<A<Y, X>>, Y extends G<A<X, Y>>> {}

main() {
  A();
}
