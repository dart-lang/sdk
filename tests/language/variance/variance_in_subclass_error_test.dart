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
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'LegacyCovariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class B<in T> implements LegacyCovariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'LegacyCovariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class C<in T> with MLegacyCovariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MLegacyCovariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class D<in T> extends Covariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class E<in T> implements Covariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class F<in T> with MCovariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MCovariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class G<in T> extends Invariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class H<in T> implements Invariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class I<in T> with MInvariant<T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MInvariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class J<in T> extends Covariant<Covariant<T>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class K<in T> extends Contravariant<Contravariant<T>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Contravariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class L<in T> extends Covariant<CovFunction<T>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class M<in T> extends Covariant<ContraFunction<ContraFunction<T>>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class N<in T> extends Contravariant<CovFunction<Contravariant<T>>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Contravariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class O<in T> extends Covariant<CovFunction<Covariant<T>>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class P<in T> extends Covariant<Covariant<Covariant<T>>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class Q<in T> extends Invariant<InvFunction<T>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class R<in T> = Covariant<T> with MContravariant<T>;
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class S<in T> = Contravariant<T> with MCovariant<T>;
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MCovariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class T<in X> = Invariant<X> with MInvariant<X>;
//    ^
// [cfe] Can't use 'in' type variable 'X' in an 'inout' position in supertype 'Invariant'.
//    ^
// [cfe] Can't use 'in' type variable 'X' in an 'inout' position in supertype 'MInvariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
