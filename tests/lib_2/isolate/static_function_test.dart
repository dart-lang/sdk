// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test starting isolate with static functions (and toplevel ones, for sanity).

library static_function_test;

import 'dart:isolate';
import 'dart:async';
import 'static_function_lib.dart' as lib;
import 'package:unittest/unittest.dart';
import 'remote_unittest_helper.dart';

void function(SendPort port) {
  port.send("TOP");
}

void _function(SendPort port) {
  port.send("_TOP");
}

// A closure created at top-level (not inside a method), but not by a top-level
// function declaration.
var staticClosure = (SendPort port) {
  port.send("WHAT?");
};

// An unnamed closure created inside a function.
get dynamicClosure => (SendPort port) {
      port.send("WHAT??");
    };

// A named closure created inside a function.
get namedDynamicClosure {
  void foo(SendPort port) {
    port.send("WHAT FOO??");
  }

  ;
  return foo;
}

class C {
  // Unnamed closure created during object initialization, but not inside
  // a method or constructor.
  final Function instanceClosure = (SendPort port) {
    port.send("C WHAT?");
  };
  // Unnamed closure created during object initializer list evaluation.
  final Function constructorInitializerClosure;
  // Unnamed closure created inside constructor body.
  Function constructorBodyClosure;
  // Named closure created inside constructor body.
  Function namedConstructorBodyClosure;

  C()
      : constructorInitializerClosure = ((SendPort port) {
          port.send("Init?");
        }) {
    constructorBodyClosure = (SendPort port) {
      port.send("bodyClosure?");
    };
    void foo(SendPort port) {
      port.send("namedBodyClosure?");
    }

    namedConstructorBodyClosure = foo;
  }

  static void function(SendPort port) {
    port.send("YES");
  }

  static void _function(SendPort port) {
    port.send("PRIVATE");
  }

  void instanceMethod(SendPort port) {
    port.send("INSTANCE WHAT?");
  }
}

class _C {
  static void function(SendPort port) {
    port.send("_YES");
  }

  static void _function(SendPort port) {
    port.send("_PRIVATE");
  }
}

void spawnTest(name, function, response) {
  test(name, () {
    ReceivePort r = new ReceivePort();
    Isolate.spawn(function, r.sendPort);
    r.listen(expectAsync((v) {
      expect(v, response);
      r.close();
    }));
  });
}

void functionFailTest(name, function) {
  test("throws on $name", () {
    Isolate.spawn(function, null).catchError(expectAsync((e) {
      /* do nothing */
    }));
  });
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  // Sanity check.
  spawnTest("function", function, "TOP");
  spawnTest("_function", _function, "_TOP");
  spawnTest("lib.function", lib.function, "LIBTOP");
  spawnTest("lib._function", lib.privateFunction, "_LIBTOP");

  // Local static functions.
  spawnTest("class.function", C.function, "YES");
  spawnTest("class._function", C._function, "PRIVATE");
  spawnTest("_class._function", _C.function, "_YES");
  spawnTest("_class._function", _C._function, "_PRIVATE");

  // Imported static functions.
  spawnTest("lib.class.function", lib.C.function, "LIB");
  spawnTest("lib.class._function", lib.C.privateFunction, "LIBPRIVATE");
  spawnTest("lib._class._function", lib.privateClassFunction, "_LIB");
  spawnTest("lib._class._function", lib.privateClassAndFunction, "_LIBPRIVATE");

  // Negative tests
  functionFailTest("static closure", staticClosure);
  functionFailTest("dynamic closure", dynamicClosure);
  functionFailTest("named dynamic closure", namedDynamicClosure);
  functionFailTest("instance closure", new C().instanceClosure);
  functionFailTest(
      "initializer closure", new C().constructorInitializerClosure);
  functionFailTest("constructor closure", new C().constructorBodyClosure);
  functionFailTest(
      "named constructor closure", new C().namedConstructorBodyClosure);
  functionFailTest("instance method", new C().instanceMethod);
}
