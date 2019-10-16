// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subclass usage for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef CovFunction<T> = T Function();
typedef ContraFunction<T> = void Function(T);
typedef InvFunction<T> = T Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}
mixin MCovariant<out T> {}
mixin MContravariant<in T> {}
mixin MInvariant<in T> {}

class A<out T> extends Contravariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Contravariant'.

class B<out T> implements Contravariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Contravariant'.

class C<out T> with MContravariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'MContravariant'.

class D<out T> extends Invariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Invariant'.

class E<out T> implements Invariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Invariant'.

class F<out T> with MInvariant<T> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'MInvariant'.

class G<out T> extends Covariant<Contravariant<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class H<out T> extends Contravariant<Covariant<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Contravariant'.

class I<out T> extends Covariant<ContraFunction<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class J<out T> extends Covariant<ContraFunction<CovFunction<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class K<out T> extends Covariant<CovFunction<ContraFunction<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class L<out T> extends Covariant<ContraFunction<Covariant<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class M<out T> extends Contravariant<Contravariant<Contravariant<T>>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Contravariant'.

class N<out T> extends Covariant<InvFunction<T>> {}
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Covariant'.

class O<out T> = Covariant<T> with MContravariant<T>;
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'MContravariant'.

class P<out T> = Contravariant<T> with MCovariant<T>;
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Contravariant'.

class Q<out T> = Invariant<T> with MInvariant<T>;
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'Invariant'.
//    ^
// [analyzer] unspecified
// [cfe] Found unsupported uses of 'T' in supertype 'MInvariant'.
