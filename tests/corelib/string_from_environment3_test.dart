// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const String.fromEnvironment('NOT_FOUND', defaultValue: 1); // //# 01: compile-time error
  const String.fromEnvironment('NOT_FOUND', defaultValue: true); // //# 02: compile-time error
  const String.fromEnvironment(null); // //# 03: compile-time error
  const String.fromEnvironment(1); // //# 04: compile-time error
  const String.fromEnvironment([]); // //# 05: compile-time error
}
