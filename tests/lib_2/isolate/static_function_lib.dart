// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library static_function_testlib;

import "dart:isolate" show SendPort;

// Used by static_function_test.dart.

void function(port) {
  port.send("LIBTOP");
}

void _function(port) {
  port.send("_LIBTOP");
}

Function get privateFunction => _function;

class C {
  static void function(SendPort port) {
    port.send("LIB");
  }

  static void _function(SendPort port) {
    port.send("LIBPRIVATE");
  }

  static Function get privateFunction => _function;
}

Function get privateClassFunction => _C.function;
Function get privateClassAndFunction => _C._function;

class _C {
  static void function(SendPort port) {
    port.send("_LIB");
  }

  static void _function(SendPort port) {
    port.send("_LIBPRIVATE");
  }
}
