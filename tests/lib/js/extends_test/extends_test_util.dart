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
  external JSClass();
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

external AnonymousClass get anon;
external AnonymousExtendAnonymousClass get anonExtendAnon;
external AnonymousExtendJSClass get anonExtendJS;

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
      if (arguments.length == 0) a = 1;
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
    self.anon = new JSClass(1);
    self.anonExtendAnon = new JSExtendAnonymousClass(1, 2);
    self.anonExtendJS = new JSExtendJSClass(1, 2);
  """);
}

void setUpWithES6Syntax() {
  // Use the ES6 syntax for classes to make inheritance easier.
  eval(r"""
    class JSClass {
      constructor(a) {
        if (arguments.length == 0) a = 1;
        this.a = a;
      }
      getA() {
        return this.a;
      }
      getAOrB() {
        return this.getA();
      }
    }
    self.JSClass = JSClass;
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
    self.anon = new JSClass(1);
    self.anonExtendAnon = new JSExtendAnonymousClass(1, 2);
    self.anonExtendJS = new JSExtendJSClass(1, 2);
  """);
}

void testInheritance() {
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

  // Test type checking and casts succeeds regardless of type hierarchy.

  // Test type checking at runtime by disabling inlining. We still, however, do
  // `is` checks directly below to test those optimizations.
  @pragma('dart2js:noInline')
  void runtimeIsAndAs<T>(instance) {
    expect(instance is T, true);
    expect(() => instance as T, returnsNormally);
  }

  // Test that base JS type can be used as any subtype.
  var js = JSClass();
  expect(js is JSExtendJSClass, true);
  runtimeIsAndAs<JSExtendJSClass>(js);
  expect(js is AnonymousExtendJSClass, true);
  runtimeIsAndAs<AnonymousExtendJSClass>(js);

  // Test that base anonymous type can be use as any subtype.
  // Conversion from external getter value to a variable is needed to coerce
  // compile time optimization of type checks. This applies for below as well.
  var anonVar = anon;
  expect(anonVar is JSExtendAnonymousClass, true);
  runtimeIsAndAs<JSExtendAnonymousClass>(anonVar);
  expect(anonVar is AnonymousExtendAnonymousClass, true);
  runtimeIsAndAs<AnonymousExtendAnonymousClass>(anonVar);

  // Test that instance of subtypes can be used as their JS supertype.
  expect(jsExtendJS is JSClass, true);
  runtimeIsAndAs<JSClass>(jsExtendJS);
  var anonExtendJSVar = anonExtendJS;
  expect(anonExtendJSVar is JSClass, true);
  runtimeIsAndAs<JSClass>(anonExtendJSVar);

  // Test that instance of subtypes can be used as their anonymous supertype.
  var anonExtendAnonVar = anonExtendAnon;
  expect(anonExtendAnonVar is AnonymousClass, true);
  runtimeIsAndAs<AnonymousClass>(anonExtendAnonVar);
  expect(jsExtendAnon is AnonymousClass, true);
  runtimeIsAndAs<AnonymousClass>(jsExtendAnon);
}

JSClass returnJS() => throw '';

AnonymousClass returnAnon() => throw '';

JSExtendJSClass returnJSExtendJS() => throw '';

JSExtendAnonymousClass returnJSExtendAnon() => throw '';

AnonymousExtendJSClass returnAnonExtendJS() => throw '';

AnonymousExtendAnonymousClass returnAnonExtendAnon() => throw '';

@pragma('dart2js:noInline')
void isRuntimeSubtypeBothWays<T, U>() {
  // Test T <: U and U <: T. With interop types, type checks should pass
  // regardless of type hierarchy. Note that dart2js does these type checks at
  // runtime. Below, we do compile-time checks using top-level functions.
  T f1() => throw '';
  U f2() => throw '';
  expect(f1 is U Function(), true);
  expect(f2 is T Function(), true);
}

void testSubtyping() {
  // Test subtyping for inheritance between JS and anonymous classes.
  expect(returnJS is JSExtendJSClass Function(), true);
  expect(returnJSExtendJS is JSClass Function(), true);
  isRuntimeSubtypeBothWays<JSClass, JSExtendJSClass>();

  expect(returnJS is AnonymousExtendJSClass Function(), true);
  expect(returnAnonExtendJS is JSClass Function(), true);
  isRuntimeSubtypeBothWays<JSClass, AnonymousExtendJSClass>();

  expect(returnAnon is JSExtendAnonymousClass Function(), true);
  expect(returnJSExtendAnon is AnonymousClass Function(), true);
  isRuntimeSubtypeBothWays<AnonymousClass, JSExtendAnonymousClass>();

  expect(returnAnon is AnonymousExtendAnonymousClass Function(), true);
  expect(returnAnonExtendAnon is AnonymousClass Function(), true);
  isRuntimeSubtypeBothWays<AnonymousClass, AnonymousExtendAnonymousClass>();
}
