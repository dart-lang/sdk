// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various invalid type-declaration combinations.

// Types must be class types.
mixin M on void {} //# 01: compile-time error
mixin M on double {} //# 02: compile-time error
mixin M on FutureOr<int> {} //# 03: compile-time error
mixin M on FunType {} //# 04: compile-time error

mixin M implements void {} //# 05: compile-time error
mixin M implements double {} //# 06: compile-time error
mixin M implements FutureOr<int> {} //# 07: compile-time error
mixin M implements FunType {} //# 08: compile-time error

// Types must be extensible.
mixin M on bool {} //# 09: compile-time error
mixin M on num {} //# 10: compile-time error
mixin M on int {} //# 11: compile-time error
mixin M on double {} //# 12: compile-time error
mixin M on Null {} //# 13: compile-time error
mixin M on String {} //# 14: compile-time error
mixin M implements bool {} //# 15: compile-time error
mixin M implements num {} //# 16: compile-time error
mixin M implements int {} //# 17: compile-time error
mixin M implements double {} //# 18: compile-time error
mixin M implements Null {} //# 19: compile-time error
mixin M implements String {} //# 20: compile-time error

// Mixin type cannot depend on itself
mixin M on M {} //# 21: compile-time error
mixin M implements M {} //# 22: compile-time error

// Types must exist and be valid
mixin M on Undeclared {} //# 23: compile-time error
mixin M on A<int> {} //# 24: compile-time error
mixin M implements Undeclared {} //# 25: compile-time error
mixin M implements A<int> {} //# 26: compile-time error

main() {}

// Just to have some types.
class A {}
class B {}
typedef FuntType = int Function(int);
