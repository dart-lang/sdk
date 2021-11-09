// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test starting isolate with static functions (and toplevel ones, for sanity).

library static_function_test;

import 'dart:io';
import 'dart:isolate';
import 'static_function_lib.dart' as lib;
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

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
  print(name);
  ReceivePort r = new ReceivePort();
  Isolate.spawn(function, r.sendPort);
  asyncStart();
  r.listen((v) {
    Expect.equals(v, response);
    r.close();
    asyncEnd();
  });
}

void functionFailTest(name, function) {
  print("throws on $name");
  asyncStart();
  Isolate.spawn(function, null).catchError((e) {
    /* do nothing */
    asyncEnd();
  });
}

void main([args, port]) {
  asyncStart();
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

  spawnTest("static closure", staticClosure, "WHAT?");
  spawnTest("dynamic closure", dynamicClosure, "WHAT??");
  spawnTest("named dynamic closure", namedDynamicClosure, "WHAT FOO??");
  spawnTest("instance closure", new C().instanceClosure, "C WHAT?");
  spawnTest(
      "initializer closure", new C().constructorInitializerClosure, "Init?");
  spawnTest(
      "constructor closure", new C().constructorBodyClosure, "bodyClosure?");
  spawnTest("named constructor closure", new C().namedConstructorBodyClosure,
      "namedBodyClosure?");
  spawnTest("instance method", new C().instanceMethod, "INSTANCE WHAT?");

  asyncEnd();
}
