// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing default factories defined across libraries

#library("lib");
#import("default_factory_library_test.dart", prefix:"test");

// References a factory class in another library
interface A default test.C {
  A();
  int methodA();
}
