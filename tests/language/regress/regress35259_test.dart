// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Supertype {
  factory Supertype() = Unresolved;
  //                    ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_NON_CLASS
  // [cfe] Couldn't find constructor 'Unresolved'.
  //                    ^
  // [cfe] Redirection constructor target not found: 'Unresolved'
  factory Supertype() = Unresolved;
//        ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
//        ^
// [cfe] 'Supertype' is already declared in this scope.
//                      ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_NON_CLASS
// [cfe] Couldn't find constructor 'Unresolved'.
//                      ^
// [cfe] Redirection constructor target not found: 'Unresolved'
}

main() {
  print(new Supertype());
  //        ^
  // [cfe] Can't use 'Supertype' because it is declared more than once.
}
