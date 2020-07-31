// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that ensures stack traces have user friendly names from extension
// functions.

import 'dart:core';
import "package:expect/expect.dart";

class C<T> {
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

extension ext<T> on C<T> {
  func() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.func'));
    }
  }

  get prop {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.prop'));
    }
  }

  set prop(value) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.prop='));
    }
  }

  operator +(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.+'));
    }
  }

  operator -(val) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.-'));
    }
  }

  static int sfld = C.tracefunc();
  static sfunc() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.sfunc'));
    }
  }

  static get sprop {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.sprop'));
    }
  }

  static set sprop(value) {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      Expect.isTrue(s.toString().contains('ext.sprop='));
    }
  }
}

main() {
  C<int> c = new C<int>();
  c.func();
  c.prop;
  c.prop = 10;
  ext.sfunc();
  ext.sprop;
  ext.sprop = 10;
  ext.sfld;
  c + 1;
  c - 1;
}
