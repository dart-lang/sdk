// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that all final instance fields of a class are initialized by
// constructors.

class Klass {
  Klass(var v) : field_ = v {}
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.FINAL_NOT_INITIALIZED_CONSTRUCTOR
  final uninitializedFinalField_;
  //    ^
  // [cfe] Final field 'uninitializedFinalField_' is not initialized.
  final uninitializedFinalField_;
  //    ^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'uninitializedFinalField_' is already declared in this scope.
  var field_;
}

main() {
  new Klass(5);
}
