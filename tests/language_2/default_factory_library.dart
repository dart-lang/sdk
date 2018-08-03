// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing default factories defined across libraries

library lib;

import "default_factory_library_test.dart" as test;

// References a factory class in another library
abstract class A {
  factory A() = test.C.A;
  int methodA();
}
