// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  const bool.fromEnvironment('NOT_FOUND', defaultValue: ''); // //# 01: compile-time error
  const bool.fromEnvironment('NOT_FOUND', defaultValue: 1); // //# 02: compile-time error
  const bool.fromEnvironment(null); // //# 03: compile-time error
  const bool.fromEnvironment(1); // //# 04: compile-time error
  const bool.fromEnvironment([]); // //# 05: compile-time error
}
