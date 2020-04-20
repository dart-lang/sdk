// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error for a class to extend, implement, or mixin the type
// Never.
class A extends Never {} //# 01: compile-time error

class A implements Never {} //# 02: compile-time error

class A with Never {} //# 03: compile-time error

mixin M on Never {} //# 04: compile-time error

main() {}
