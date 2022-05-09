// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T castObject<T>(Object value) => value as T;

main() {
  print((castObject(true)..whatever()) ? 1 : 2);
  //                       ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'whatever' isn't defined for the class 'bool'.
}
