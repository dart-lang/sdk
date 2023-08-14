// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

null_() => null;
final Undeclared x = null_();
//    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] 'Undeclared' isn't a type.
// [cfe] Type 'Undeclared' not found.

main() {
  print(x);
}
