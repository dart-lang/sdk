// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'extends_test_util.dart';

void main() {
  // Use the ES6 syntax for classes to make inheritance easier.
  eval(r"""
    class JSClass {
      constructor(a) {
        this.a = a;
      }
      getA() {
        return this.a;
      }
      getAOrB() {
        return this.getA();
      }
    }
    class JSExtendJSClass extends JSClass {
      constructor(a, b) {
        super(a);
        this.b = b;
      }
      getB() {
        return this.b;
      }
      getAOrB() {
        return this.getB();
      }
    }
    self.JSExtendJSClass = JSExtendJSClass;
    class JSExtendAnonymousClass {
      constructor(a, b) {
        this.a = a;
        this.b = b;
      }
      getA() {
        return this.a;
      }
      getB() {
        return this.b;
      }
      getAOrB() {
        return this.getB();
      }
    }
    self.JSExtendAnonymousClass = JSExtendAnonymousClass;
    self.anonExtendAnon = new JSExtendAnonymousClass(1, 2);
    self.anonExtendJS = new JSExtendJSClass(1, 2);
  """);
  testInheritance();
}
