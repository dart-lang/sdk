// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors when the type parameters of the shorthand methods don't match the
// context type.

import '../dot_shorthand_helper.dart';

void main() {
  StaticMember<bool> s = .member();
  //                     ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'StaticMember<int>' can't be assigned to a variable of type 'StaticMember<bool>'.

  StaticMember<int> sTypeParameters = .memberType("s");
  //                                              ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.

  StaticMemberExt<bool> sExt = .member();
  //                           ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'StaticMemberExt<int>' can't be assigned to a variable of type 'StaticMemberExt<bool>'.

  StaticMemberExt<int> sTypeParametersExt = .memberType("s");
  //                                                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}
