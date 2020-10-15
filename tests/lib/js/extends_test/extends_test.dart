// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'extends_test_util.dart';

void main() {
  // Use the old way to define inheritance between JS objects.
  eval(r"""
    function inherits(child, parent) {
      if (child.prototype.__proto__) {
        child.prototype.__proto__ = parent.prototype;
      } else {
        function tmp() {};
        tmp.prototype = parent.prototype;
        child.prototype = new tmp();
        child.prototype.constructor = child;
      }
    }
    function JSClass(a) {
      this.a = a;
      this.getA = function() {
        return this.a;
      }
      this.getAOrB = function() {
        return this.getA();
      }
    }
    function JSExtendJSClass(a, b) {
      JSClass.call(this, a);
      this.b = b;
      this.getB = function() {
        return this.b;
      }
      this.getAOrB = function() {
        return this.getB();
      }
    }
    inherits(JSExtendJSClass, JSClass);
    function JSExtendAnonymousClass(a, b) {
      this.a = a;
      this.b = b;
      this.getA = function() {
        return this.a;
      }
      this.getB = function() {
        return this.b;
      }
      this.getAOrB = function() {
        return this.getB();
      }
    }
    self.anonExtendAnon = new JSExtendAnonymousClass(1, 2);
    self.anonExtendJS = new JSExtendJSClass(1, 2);
  """);
  testInheritance();
}
