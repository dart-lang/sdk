// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that ensures stack traces have user friendly names from extension
// functions.

import 'dart:core';
import "package:expect/expect.dart";

class C {
  static int tracefunc() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('C.tracefunc'));
      Expect.isTrue(s.toString().contains('ext.sfld'));
    }
    return 10;
  }

  static int ld = C.tracefunc();
}

extension on C {
  func() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#0.func'));
    }
  }

  get prop {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#0.prop'));
    }
  }

  set prop(value) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#0.prop='));
    }
  }

  operator +(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#0.+'));
    }
  }

  operator -(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#0.-'));
    }
  }
}

extension on C {
  bar() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('_extension#1.bar'));
    }
  }
}

main() {
  C c = new C();
  c.func();
  c.prop;
  c.prop = 10;
  c + 1;
  c - 1;
  c.bar();
}
