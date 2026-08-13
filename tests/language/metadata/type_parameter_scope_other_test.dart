// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that identifiers in type parameter metadata can refer to other type
// parameters in the same declaration; they are in scope and take precedence
// over top level declarations, even if this leads to compile errors.

/// Top level declaration of T; nothing should resolve to this.
void T() {}

class Annotation {
  const Annotation(dynamic d);
}

class Class<T, @Annotation(T) U> {}
//                         ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.

void function<T, @Annotation(T) U>() {}
//                           ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.

extension Extension<T, @Annotation(T) U> on Map<T, U> {}
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.

class C {
  void method<T, @Annotation(T) U>() {}
  //                         ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
  // [cfe] Type variables can't be used as constants.
}

mixin Mixin<T, @Annotation(T) U> {}
//                         ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.

typedef void Typedef1<T, @Annotation(T) U>(T t, U u);
//                                   ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.

typedef Typedef2<T, @Annotation(T) U> = void Function(T t, U u);
//                              ^
// [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
// [cfe] Type variables can't be used as constants.
