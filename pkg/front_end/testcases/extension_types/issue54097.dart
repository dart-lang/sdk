// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1<X>(X it) {}

class A1<X extends E1<X>> {} // Error.
typedef F1<X extends E1<X>> = int; // Error.
typedef G1 = void Function<X extends E1<X>>(); // Error.
typedef void H1<X extends E1<X>>(); // Error.
extension Ext1<X extends E1<X>> on List<X> {} // Error.
enum Enum1<X extends E1<X>> { element<Never>(); } // Error.
foo1<X extends E1<X>>() {} // Error.
mixin M1<X extends E1<X>> on List<num> {} // Error.
bar1() {
  var x = <X extends E1<X>>() {}; // Error.
  f<X extends E1<X>>() {}; // Error.
}
extension type ET1<X extends E1<X>>(Object? it) {} // Error.

class A2<X extends E1<Y>, Y extends X> {} // Error.
typedef F2<X extends E1<Y>, Y extends X> = int; // Error.
typedef G2 = void Function<X extends E1<Y>, Y extends X>(); // Error.
typedef void H2<X extends E1<Y>, Y extends X>(); // Error.
extension Ext2<X extends E1<Y>, Y extends X> on List<X> {} // Error.
enum Enum2<X extends E1<Y>, Y extends X> { element<Never, Never>(); } // Error.
foo2<X extends E1<Y>, Y extends X>() {} // Error.
mixin M2<X extends E1<Y>, Y extends X> on List<num> {} // Error.
bar2() {
  var x = <X extends E1<Y>, Y extends X>() {}; // Error.
  f<X extends E1<Y>, Y extends X>() {}; // Error.
}
extension type ET2<X extends E1<Y>, Y extends X>(Object? it) {} // Error.
