// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests inheritance relationships between `JS` and `anonymous` classes/objects.

@JS()
library extends_test;

import 'package:expect/minitest.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS()
class JSClass {
  external int get a;
  external int getA();
  external int getAOrB();
}

@JS()
@anonymous
class AnonymousClass {
  external int get a;
  external int getA();
}

@JS()
class JSExtendJSClass extends JSClass {
  external JSExtendJSClass(int a, int b);
  external int get b;
  external int getB();
  external int getAOrB();
}

@JS()
class JSExtendAnonymousClass extends AnonymousClass {
  external JSExtendAnonymousClass(int a, int b);
  external int get b;
  external int getB();
}

@JS()
@anonymous
class AnonymousExtendAnonymousClass extends AnonymousClass {
  external int get b;
  external int getB();
}

@JS()
@anonymous
class AnonymousExtendJSClass extends JSClass {
  external int get b;
  external int getB();
  external int getAOrB();
}

external AnonymousExtendAnonymousClass get anonExtendAnon;
external AnonymousExtendJSClass get anonExtendJS;

void useJSClass(JSClass js) {}
void useAnonymousClass(AnonymousClass a) {}

void setUpWithoutES6Syntax() {
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
}

void setUpWithES6Syntax() {
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
}

void testInheritance() {
  // Note that for the following, there are no meaningful tests for is checks or
  // as casts, since the web compilers should return true and succeed for all JS
  // types.

  var jsExtendJS = JSExtendJSClass(1, 2);
  expect(jsExtendJS.a, 1);
  expect(jsExtendJS.b, 2);
  expect(jsExtendJS.getA(), 1);
  expect(jsExtendJS.getB(), 2);
  // Test method overrides.
  expect(jsExtendJS.getAOrB(), 2);
  expect((jsExtendJS as JSClass).getAOrB(), 2);

  var jsExtendAnon = JSExtendAnonymousClass(1, 2);
  expect(jsExtendAnon.a, 1);
  expect(jsExtendAnon.b, 2);
  expect(jsExtendAnon.getA(), 1);
  expect(jsExtendAnon.getB(), 2);

  expect(anonExtendAnon.a, 1);
  expect(anonExtendAnon.b, 2);
  expect(anonExtendAnon.getA(), 1);
  expect(anonExtendAnon.getB(), 2);

  expect(anonExtendJS.a, 1);
  expect(anonExtendJS.b, 2);
  expect(anonExtendJS.getA(), 1);
  expect(anonExtendJS.getB(), 2);
  expect(anonExtendJS.getAOrB(), 2);
  expect((anonExtendJS as JSClass).getAOrB(), 2);
}

void testSubtyping() {
  // Test subtyping for inheritance between JS and anonymous classes.
  expect(useJSClass is void Function(JSExtendJSClass js), true);
  expect(useAnonymousClass is void Function(AnonymousExtendAnonymousClass a),
      true);
  expect(useJSClass is void Function(AnonymousExtendJSClass a), true);
  expect(useAnonymousClass is void Function(JSExtendAnonymousClass js), true);

  expect(useJSClass is void Function(AnonymousExtendAnonymousClass a), false);
  expect(useAnonymousClass is void Function(JSExtendJSClass js), false);
  expect(useJSClass is void Function(JSExtendAnonymousClass js), false);
  expect(useAnonymousClass is void Function(AnonymousExtendJSClass a), false);
}
