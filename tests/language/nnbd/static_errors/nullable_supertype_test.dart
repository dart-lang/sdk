// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that it is an error to use a nullable type as a supertype.
import 'package:expect/expect.dart';
import 'dart:core';
import 'dart:core' as core;

main() {}

class A {}
class B extends A? {} //# 01: syntax error
class B implements A? {} //# 02: syntax error
class B with A? {} //# 03: syntax error
mixin B on A? {} //# 04: syntax error
mixin B implements A? {} //# 05: syntax error
