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
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'Covariant'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class B<in T> extends MultiThree<T, T, T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MultiThree'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class C<in T, out U, inout V> extends MultiTwo<U, T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//                ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class D<in T, out U, inout V> extends MultiThree<V, U, T> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'inout' position in supertype 'MultiThree'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class E<in T, out U, inout V> extends MultiThree<Covariant<U>, Covariant<T>, Covariant<U>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiThree'.
//    ^
// [cfe] Can't use 'out' type variable 'U' in an 'inout' position in supertype 'MultiThree'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//                ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class F<in T, out U, inout V> extends MultiTwo<Contravariant<T>, Contravariant<U>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//                ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class G<in T, out U, inout V> extends MultiThree<CovFunction<U>, CovFunction<T>, CovFunction<U>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiThree'.
//    ^
// [cfe] Can't use 'out' type variable 'U' in an 'inout' position in supertype 'MultiThree'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//                ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE

class H<in T, out U, inout V> extends MultiTwo<ContraFunction<T>, ContraFunction<U>> {}
//    ^
// [cfe] Can't use 'in' type variable 'T' in an 'out' position in supertype 'MultiTwo'.
//    ^
// [cfe] Can't use 'out' type variable 'U' in an 'in' position in supertype 'MultiTwo'.
//         ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
//                ^
// [analyzer] COMPILE_TIME_ERROR.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE
