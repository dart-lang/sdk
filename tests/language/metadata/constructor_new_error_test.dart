// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'constructor_new_error_test.dart' as self;

class Class {
  const Class();
}

class GenericClass<X, Y> {
  const GenericClass();
}

@Class.new
// [error column 1, length 10]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
// [error column 2]
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
@GenericClass.new
// [error column 1, length 17]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
// [error column 2]
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
@GenericClass<int, String>.new
// [error column 1, length 30]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
// [error column 2]
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
//                         ^^^
// [analyzer] SYNTACTIC_ERROR.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED
// [cfe] An annotation with type arguments must be followed by an argument list.
@self.Class.new
// [error column 1, length 15]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
//    ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
@self.GenericClass.new
// [error column 1, length 22]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
//    ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
@self.GenericClass<int, String>.new
// [error column 1, length 35]
// [analyzer] COMPILE_TIME_ERROR.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS
//    ^
// [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
//                              ^^^
// [analyzer] SYNTACTIC_ERROR.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED
// [cfe] An annotation with type arguments must be followed by an argument list.
main() {}
