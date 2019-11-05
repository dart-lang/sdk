// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous variance usage multiple type parameters.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}

class MultiTwo<in T, out U> {}
class MultiThree<in T, out U, inout V> {}

class A<in T, out U, inout V> extends Covariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class B<in T> extends MultiThree<T, T, T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MultiThree'.

class C<in T, out U, inout V> extends MultiTwo<U, T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.

class D<in T, out U, inout V> extends MultiThree<V, U, T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MultiThree'.

class E<in T, out U, inout V> extends MultiThree<Covariant<U>, Covariant<T>, Covariant<U>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiThree'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'out' type variable 'U' in an 'inout' position in supertype 'MultiThree'.

class F<in T, out U, inout V> extends MultiTwo<Contravariant<T>, Contravariant<U>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.

class G<in T, out U, inout V> extends MultiThree<CovFunction<U>, CovFunction<T>, CovFunction<U>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiThree'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'out' type variable 'U' in an 'inout' position in supertype 'MultiThree'.

class H<in T, out U, inout V> extends MultiTwo<ContraFunction<T>, ContraFunction<U>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.
