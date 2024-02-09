// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// This test verifies that cyclic type alias definitions cause a compile-time
// error, when the cycle occurs via the expansion of the type.

typedef T1 = List<T1>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T1' has a reference to itself.

typedef T2 = List<T3>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T2' has a reference to itself.

// Note: when the cycle involves two typedefs, the CFE only reports an error for
// one of them; that's ok.
typedef T3 = List<T2>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T3' has a reference to itself.

typedef T4 = T4;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T4' has a reference to itself.

typedef T5 = T5?;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T5' has a reference to itself.

typedef T6 = List<T6 Function()>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T6' has a reference to itself.

typedef T7 = List<void Function(T7)>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T7' has a reference to itself.

// Note: not an error because T8 is the name of the parameter.
typedef T8 = List<void Function(int T8)>;

typedef T9 = List<void Function([T9])>;
//      ^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T9' has a reference to itself.

// Note: not an error because T10 is the name of the parameter.
typedef T10 = List<void Function([int T10])>;

typedef T11 = List<void Function({T11 x})>;
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T11' has a reference to itself.

// Note: not an error because T12 is the name of the parameter.
typedef T12 = List<void Function({int T12})>;

// Note: we have to use `void Function<...>() Function()` because a generic
// function can't directly be used as a type argument.
typedef T13 = List<void Function<X extends T13>() Function()>;
//      ^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'T13' has a reference to itself.
//                                         ^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND
