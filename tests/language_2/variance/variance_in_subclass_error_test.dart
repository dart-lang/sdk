// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subclass usage for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);
typedef InvFunction<T> = T Function(T);

class LegacyCovariant<T> {}
class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}
mixin MLegacyCovariant<T> {}
mixin MCovariant<out T> {}
mixin MContravariant<in T> {}
mixin MInvariant<inout T> {}

class A<in T> extends LegacyCovariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'LegacyCovariant'.

class B<in T> implements LegacyCovariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'LegacyCovariant'.

class C<in T> with MLegacyCovariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MLegacyCovariant'.

class D<in T> extends Covariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class E<in T> implements Covariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class F<in T> with MCovariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MCovariant'.

class G<in T> extends Invariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.

class H<in T> implements Invariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.

class I<in T> with MInvariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MInvariant'.

class J<in T> extends Covariant<Covariant<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class K<in T> extends Contravariant<Contravariant<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Contravariant'.

class L<in T> extends Covariant<CovFunction<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class M<in T> extends Covariant<ContraFunction<ContraFunction<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class N<in T> extends Contravariant<CovFunction<Contravariant<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Contravariant'.

class O<in T> extends Covariant<CovFunction<Covariant<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class P<in T> extends Covariant<Covariant<Covariant<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class Q<in T> extends Invariant<InvFunction<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.

class R<in T> = Covariant<T> with MContravariant<T>;
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.

class S<in T> = Contravariant<T> with MCovariant<T>;
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MCovariant'.

class T<in X> = Invariant<X> with MInvariant<X>;
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'X' in an 'inout' position in supertype 'Invariant'.
//    ^
// [analyzer] unspecified
// [cfe] Can't use 'in' type variable 'X' in an 'inout' position in supertype 'MInvariant'.
