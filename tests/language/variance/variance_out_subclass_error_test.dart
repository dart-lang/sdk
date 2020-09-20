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
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class B<out T> implements Contravariant<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class C<out T> with MContravariant<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'MContravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class D<out T> extends Invariant<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class E<out T> implements Invariant<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class F<out T> with MInvariant<T> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'MInvariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class G<out T> extends Covariant<Contravariant<T>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class H<out T> extends Contravariant<Covariant<T>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class I<out T> extends Covariant<ContraFunction<T>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class J<out T> extends Covariant<ContraFunction<CovFunction<T>>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class K<out T> extends Covariant<CovFunction<ContraFunction<T>>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class L<out T> extends Covariant<ContraFunction<Covariant<T>>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class M<out T> extends Contravariant<Contravariant<Contravariant<T>>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class N<out T> extends Covariant<InvFunction<T>> {}
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'inout' position in supertype 'Covariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class O<out T> = Covariant<T> with MContravariant<T>;
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'MContravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class P<out T> = Contravariant<T> with MCovariant<T>;
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'Contravariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class Q<out T> = Invariant<T> with MInvariant<T>;
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'in' position in supertype 'MInvariant'.
//    ^
// [cfe] Can't use 'out' type variable 'T' in an 'inout' position in supertype 'Invariant'.
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//          ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
