// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F1<X> = X;
extension type E1<X>(X it) {}
typedef F2<X> = E1<X>;
typedef F3<X> = E1<F1<X>>;
typedef F4<X> = F1<E1<X>>;
typedef F5<X> = F1<E1<F1<X>>>;
typedef F6<X> = F1<F1<X>>;
typedef F7<X> = E1<E1<X>>;
extension type E2<X>(F1<X> it) {}
extension type E3<X>(F1<E1<X>> it) {}
extension type E4<X>(E1<F1<X>> it) {}
extension type E5<X>(E1<F1<E1<X>>> it) {}
extension type E6<X>(E1<E1<X>> it) {}
extension type E7<X>(F1<F1<X>> it) {}

class A1<X extends Y, Y extends X> {} // Error.
class A2<X extends X> {} // Error.
class A3<X, Y extends Z, Z extends Y> {} // Error.

class AF11<X extends F1<X>> {} // Error.
class AF12<X extends F2<X>> {} // Error.
class AF13<X extends F3<X>> {} // Error.
class AF14<X extends F4<X>> {} // Error.
class AF15<X extends F5<X>> {} // Error.
class AF16<X extends F6<X>> {} // Error.
class AF17<X extends F7<X>> {} // Error.
class AE11<X extends E1<X>> {} // Error.
class AE12<X extends E2<X>> {} // Error.
class AE13<X extends E3<X>> {} // Error.
class AE14<X extends E4<X>> {} // Error.
class AE15<X extends E5<X>> {} // Error.
class AE16<X extends E6<X>> {} // Error.
class AE17<X extends E7<X>> {} // Error.

test() {
  <X extends F1<X>>() {}; // Error.
  <X extends F2<X>>() {}; // Error.
  <X extends F3<X>>() {}; // Error.
  <X extends F4<X>>() {}; // Error.
  <X extends F5<X>>() {}; // Error.
  <X extends F6<X>>() {}; // Error.
  <X extends F7<X>>() {}; // Error.
  <X extends E1<X>>() {}; // Error.
  <X extends E2<X>>() {}; // Error.
  <X extends E3<X>>() {}; // Error.
  <X extends E4<X>>() {}; // Error.
  <X extends E5<X>>() {}; // Error.
  <X extends E6<X>>() {}; // Error.
  <X extends E7<X>>() {}; // Error.
}
