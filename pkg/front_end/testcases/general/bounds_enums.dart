// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Check/create this type as regular bounded i2b.

typedef A<X> = X Function(X);

class B<X> {}

enum E1<Y extends A<Y>> /* Error */ {
  e1<Never>() // Ok
}

enum E2<Y extends B<Y>> /* Error */ {
  e2<Never>() // Ok
}

enum E3<Y extends E3<Y>> /* Error */ {
  e3<Never>() // Ok
}

main() {}
