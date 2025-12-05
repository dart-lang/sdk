// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// You can only use private named parameters on parameters that refer to
/// instance fields.

// SharedOptions=--enable-experiment=private-named-parameters

class C {
  // In a generative constructor, but not an initializing formal.
  C({int? _notInitializingFormal});
  //      ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
  // [cfe] A named parameter that doesn't refer to an instance variable can't start with an underscore ('_').

  // In a factory constructor.
  factory C.fact({int? _inFactory}) => throw '!';
  //                   ^^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
  // [cfe] A named parameter that doesn't refer to an instance variable can't start with an underscore ('_').
}

// In a non-constructor function.
void function({int? _parameter}) {}
//                  ^^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
// [cfe] A named parameter that doesn't refer to an instance variable can't start with an underscore ('_').

void main() {}
