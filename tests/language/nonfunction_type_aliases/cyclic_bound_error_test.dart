// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// This test verifies that cyclic type alias definitions cause a compile-time
// error, when the cycle occurs via the bound.

typedef T1<X extends T1<Never>> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

// Note: when the cycle involves two typedefs, the CFE only reports an error for
// one of them; that's ok.
typedef T2<X extends T3> = List<X>;
//      ^
// [analyzer] unspecified

typedef T3 = T2<Never>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

typedef T4<X extends List<T4<Never>>> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

typedef T5<X extends T5<Never> Function()> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

typedef T6<X extends void Function(T6<Never>)> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

// Note: not an error because T7 is the name of the parameter.
typedef T7<X extends void Function(int T7)> = List<X>;

typedef T8<X extends void Function([T8<Never>])> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

// Note: not an error because T9 is the name of the parameter.
typedef T9<X extends void Function([int T9])> = List<X>;

typedef T10<X extends void Function({T10<Never> x})> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified

// Note: not an error because T11 is the name of the parameter.
typedef T11<X extends void Function({int T11})> = List<X>;

// Note: we have to use `void Function<...>() Function()` because a generic
// function can't directly be used as a bound.
typedef T12<X extends void Function<Y extends T12<Never>>() Function()> = List<X>;
//      ^
// [analyzer] unspecified
// [cfe] unspecified
