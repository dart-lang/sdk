// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error to use a nullable type as a supertype.
import 'package:expect/expect.dart';
import 'dart:core';
import 'dart:core' as core;

main() {}

class A {}
class B extends A? {} //# 01: compile-time error
class B implements A? {} //# 02: compile-time error
class B with A? {} //# 03: compile-time error
mixin B on A? {} //# 04: compile-time error
mixin B implements A? {} //# 05: compile-time error
