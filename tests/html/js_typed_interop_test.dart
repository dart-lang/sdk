// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/html_individual_config.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var Foo = {
    multiplyDefault2: function(a, b) {
      if (arguments.length >= 2) return a *b;
      return a * 2;
    }
  };

  var foo = {
    x: 3,
    z: 40, // Not specified in typed Dart API so should fail in checked mode.
    multiplyByX: function(arg) { return arg * this.x; },
    // This function can be torn off without having to bind this.
    multiplyBy2: function(arg) { return arg * 2; },
    multiplyDefault2Function: function(a, b) {
      if (arguments.length >= 2) return a * b;
      return a * 2;
    },
    callClosureWithArg1: function(closure, arg) {
      return closure(arg);
    },
    callClosureWithArg2: function(closure, arg1, arg2) {
      return closure(arg1, arg2);
    },
    callClosureWithArgAndThis: function(closure, arg) {
      return closure.apply(this, [arg]);
    },

    getBar: function() {
      return bar;
    }
  };

  var foob = {
    x: 8,
    y: "why",
    multiplyByX: function(arg) { return arg * this.x; }
  };

  var bar = {
    x: "foo",
    multiplyByX: true,
    getFoo: function() {
      return foo;
    }
  };

  function ClassWithConstructor(a, b) {
    this.a = a;
    this.b = b;
  };

  ClassWithConstructor.prototype = {
    getA: function() { return this.a;}
  };

  function _PrivateClass(a, b) {
    this._a = a;
    this._b = b;
  };

  _PrivateClass.prototype = {
    _getA: function() { return this._a;}
  };

  var selection = ["a", "b", "c", foo, bar];

  function returnNumArgs() { return arguments.length; };
  function returnLastArg() { return arguments[arguments.length-1]; };

  function confuse(obj) { return obj; }

  window['class'] = function() { return 42; };
  window['delete'] = 100;
  window['JS$hasJsInName'] = 'unicorn';
  window['JS$hasJsInNameMethod'] = function(x) { return x*5; };

  function JS$ClassWithJSInName(x) {
    this.x = x;
    this.JS$hasJsInName = 73;
    this.$JS$doesNotNeedEscape = 103;
  };

  JS$ClassWithJSInName.prototype = {
    JS$getXwithJsInName: function() { return this.x;}
  };

  JS$ClassWithJSInName.JS$staticMethod = function(x) { return x * 3; };

  function StringWrapper(str) {
    this.str = str;
  }
  StringWrapper.prototype = {
    charCodeAt: function(index) {
      return this.str.charCodeAt(index);
    }
  };
  function getCanvasContext() {
    return document.createElement('canvas').getContext('2d');
  }
  window.windowProperty = 42;
  document.documentProperty = 45;
""");
}

class RegularClass {
  factory RegularClass(a) {
    return new RegularClass.fooConstructor(a);
  }
  RegularClass.fooConstructor(this.a);
  var a;
}

@JS()
class ClassWithConstructor {
  external ClassWithConstructor(aParam, bParam);
  external getA();
  external get a;
  external get b;
}

@JS('ClassWithConstructor')
class _ClassWithConstructor {
  external _ClassWithConstructor(aParam, bParam);
  external getA();
  external get a;
  external get b;
}

@JS('ClassWithConstructor')
class ClassWithFactory {
  external factory ClassWithFactory(aParam, bParam);
  external getA();
  external get a;
  external get b;
}

@JS()
class JS$_PrivateClass {
  external JS$_PrivateClass(aParam, bParam);
  external JS$_getA();
  external get JS$_a;
  external get JS$_b;
  // Equivalent to JS$_a but only visible within
  // the class.
  external get _a;
}

@JS()
external String get JS$JS$hasJsInName;

@JS()
external int JS$JS$hasJsInNameMethod(int x);

// This is the preferred way to handle static or top level members that start
// with JS$. We verify that JS$JS$ works purely to prevent bugs.
@JS(r'JS$hasJsInName')
external String get JS$hasJsInName;

@JS(r'JS$hasJsInNameMethod')
external int JS$hasJsInNameMethod(int x);

@JS()
class JS$JS$ClassWithJSInName {
  external JS$JS$ClassWithJSInName(x);
  external int get x;
  external int get JS$JS$hasJsInName;
  external int get $JS$doesNotNeedEscape;
  external int JS$JS$getXwithJsInName();
  external static int JS$JS$staticMethod(x);
}

typedef num MultiplyWithDefault(num a, [num b]);

@JS()
class Foo {
  external int get x;
  external set x(int v);
  external num multiplyByX(num y);
  external num multiplyBy2(num y);
  external num JS$multiplyBy2(num y);
  external MultiplyWithDefault get multiplyDefault2Function;

  external callClosureWithArgAndThis(Function closure, arg);
  external callClosureWithArg1(Function closure, arg1);
  external callClosureWithArg2(Function closure, arg1, arg2);
  external Bar getBar();

  external static num multiplyDefault2(num a, [num b]);
  // Should desugar to multiplyDefault2.
  external static num JS$multiplyDefault2(num a, [num b]);
}

@anonymous
@JS()
class ExampleLiteral {
  external factory ExampleLiteral({int x, String y, num z, JS$class});

  external int get x;
  external int get JS$class;
  external String get y;
  external num get z;
}

@anonymous
@JS()
class EmptyLiteral {
  external factory EmptyLiteral();
}

@JS('Foob')
class Foob extends Foo {
  external String get y;
}

@JS('Bar')
class Bar {
  external String get x;
  external bool get multiplyByX;
  external Foo getFoo();
}

// No @JS is required for these external methods as the library is
// annotated with Js.
external Foo get foo;
external Foob get foob;
external Bar get bar;
external Selection get selection;

addWithDefault(a, [b = 100]) => a + b;

external Function get returnNumArgs;
external Function get returnLastArg;

const STRINGIFY_LOCATION = "JSON.stringify";
@JS(STRINGIFY_LOCATION)
external String stringify(obj);

@JS()
class StringWrapper {
  external StringWrapper(String str);
  external int charCodeAt(int i);
}

// Defeat JS type inference by calling through JavaScript interop.
@JS()
external confuse(obj);

/// Desugars to calling the js method named class.
@JS()
external JS$class();

@JS()
external get JS$delete;

@JS()
external CanvasRenderingContext2D getCanvasContext();

@JS('window.window.document.documentProperty')
external num get propertyOnDocument;

@JS('window.self.window.window.windowProperty')
external num get propertyOnWindow;

@JS()
@anonymous
class Simple {
  external List<int> get numbers;
  external set numbers(List<int> numbers);

  external factory Simple({List<int> numbers});
}

main() {
  _injectJs();

  useHtmlIndividualConfiguration();

  group('object literal', () {
    test('simple', () {
      var l = new ExampleLiteral(x: 3, y: "foo");
      expect(l.x, equals(3));
      expect(l.y, equals("foo"));
      expect(l.z, isNull);
      expect(stringify(l), equals('{"x":3,"y":"foo"}'));
      l = new ExampleLiteral(z: 100);
      expect(l.x, isNull);
      expect(l.y, isNull);
      expect(l.z, equals(100));
      expect(stringify(l), equals('{"z":100}'));
    });

    test('with array', () {
      // Repro for https://github.com/dart-lang/sdk/issues/26768
      var simple = new Simple(numbers: [1, 2, 3]);
      expect(stringify(simple), equals('{"numbers":[1,2,3]}'));
    });

    test(r'JS$ escaped name', () {
      var l = new ExampleLiteral(JS$class: 3, y: "foo");
      expect(l.JS$class, equals(3));
    });

    test('empty', () {
      var l = new EmptyLiteral();
      expect(stringify(l), equals('{}'));
    });
  });

  group('constructor', () {
    test('simple', () {
      var o = new ClassWithConstructor("foo", "bar");
      expect(o.a, equals("foo"));
      expect(o.b, equals("bar"));
      expect(o.getA(), equals("foo"));
    });
    test('external factory', () {
      var o = new ClassWithFactory("foo", "bar");
      expect(o.a, equals("foo"));
      expect(o.b, equals("bar"));
      expect(o.getA(), equals("foo"));
    });
  });

  group('private class', () {
    test('simple', () {
      var o = new _ClassWithConstructor("foo", "bar");
      expect(o.a, equals("foo"));
      expect(o.b, equals("bar"));
      expect(o.getA(), equals("foo"));
    });
  });

  group('private class', () {
    test('simple', () {
      var o = new JS$_PrivateClass("foo", "bar");
      expect(o.JS$_a, equals("foo"));
      expect(o.JS$_b, equals("bar"));
      expect(o._a, equals("foo"));
      expect(o.JS$_getA(), equals("foo"));
    });
  });

  group('property', () {
    test('get', () {
      expect(foo.x, equals(3));
      expect(foob.x, equals(8));
      expect(foob.y, equals("why"));

      // Exists in JS but not in API.
      expect(() => (foo as dynamic).zSomeInvalidName, throws);
      expect(bar.multiplyByX, isTrue);
    });
    test('set', () {
      foo.x = 42;
      expect(foo.x, equals(42));
      // Property tagged as read only in typed API.
      expect(() => (foob as dynamic).y = "bla", throws);
      expect(() => (foo as dynamic).unknownName = 42, throws);
    });
  });

  group('method', () {
    test('call', () {
      foo.x = 100;
      expect(foo.multiplyByX(4), equals(400));
      foob.x = 10;
      expect(foob.multiplyByX(4), equals(40));
    });

    test('tearoff', () {
      foo.x = 10;
      Function multiplyBy2 = foo.multiplyBy2;
      expect(multiplyBy2(5), equals(10));
      Function multiplyByX = foo.multiplyByX;
      // Tearing off a JS closure doesn't bind this.
      // You will need to use the new method tearoff syntax to bind this.
      expect(multiplyByX(4), isNaN);

      MultiplyWithDefault multiplyWithDefault = foo.multiplyDefault2Function;
      expect(multiplyWithDefault(6, 6), equals(36));
      expect(multiplyWithDefault(6), equals(12));
      Function untypedFunction = foo.multiplyDefault2Function;
      // Calling with extra bogus arguments has no impact for JavaScript
      // methods.
      expect(untypedFunction(6, 6, "ignored", "ignored"), equals(36));
      expect(
          untypedFunction(6, 6, "ignored", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
          equals(36));
      // Calling a JavaScript method with too few arguments is also fine and
      // defaults to JavaScript behavior of setting all unspecified arguments
      // to undefined resulting in multiplying undefined by 2 == NAN.
      expect(untypedFunction(), isNaN);
    });

    test(r'JS$ escaped name', () {
      foo.x = 10;
      expect(foo.JS$multiplyBy2(5), equals(10));

      Function multiplyBy2 = foo.JS$multiplyBy2;
      expect(multiplyBy2(5), equals(10));
    });

    test(r'JS$ double escaped name', () {
      var obj = new JS$JS$ClassWithJSInName(42);
      expect(obj.x, equals(42));
      expect(obj.JS$JS$getXwithJsInName(), equals(42));
      expect(obj.JS$JS$hasJsInName, equals(73));
      expect(obj.$JS$doesNotNeedEscape, equals(103));
    });
  });

  group('static_method_call', () {
    test('call directly from dart', () {
      expect(Foo.multiplyDefault2(6, 7), equals(42));
      expect(Foo.multiplyDefault2(6), equals(12));
    });

    test(r'JS$ escaped name', () {
      expect(Foo.JS$multiplyDefault2(6, 7), equals(42));
      expect(Foo.JS$multiplyDefault2(6), equals(12));
    });

    test(r'JS$ double escaped name', () {
      expect(JS$JS$ClassWithJSInName.JS$JS$staticMethod(4), equals(12));
    });
  });

  // Note: these extra groups are added to be able to mark each test
  // individually in status files. This should be split as separate test files.
  group('static_method_tearoff_1', () {
    test('call tearoff from dart', () {
      MultiplyWithDefault tearOffMethod = Foo.multiplyDefault2;
      expect(tearOffMethod(6, 6), equals(36));
    });
  });

  group('static_method_tearoff_2', () {
    test('call tearoff from dart', () {
      MultiplyWithDefault tearOffMethod = Foo.multiplyDefault2;
      expect(tearOffMethod(6), equals(12));
    });
  });

  group('closure', () {
    test('call from js', () {
      localClosure(x) => x * 10;
      var wrappedLocalClosure = allowInterop(localClosure);
      expect(
          identical(allowInterop(localClosure), wrappedLocalClosure), isTrue);
      expect(foo.callClosureWithArg1(wrappedLocalClosure, 10), equals(100));
      expect(foo.callClosureWithArg1(wrappedLocalClosure, "a"),
          equals("aaaaaaaaaa"));
      expect(foo.callClosureWithArg1(allowInterop(addWithDefault), 10),
          equals(110));
      expect(foo.callClosureWithArg2(allowInterop(addWithDefault), 10, 20),
          equals(30));
      addThisXAndArg(Foo that, int arg) {
        return foo.x + arg;
      }

      var wrappedCaptureThisClosure = allowInteropCaptureThis(addThisXAndArg);
      foo.x = 20;
      expect(foo.callClosureWithArgAndThis(wrappedCaptureThisClosure, 10),
          equals(30));
      foo.x = 50;
      expect(foo.callClosureWithArgAndThis(wrappedCaptureThisClosure, 10),
          equals(60));
      expect(
          identical(allowInteropCaptureThis(addThisXAndArg),
              wrappedCaptureThisClosure),
          isTrue);

      ExampleLiteral addXValues(that, ExampleLiteral arg) {
        return new ExampleLiteral(x: that.x + arg.x);
      }

      // Check to make sure returning a JavaScript value from a Dart closure
      // works as expected.
      expect(
          foo
              .callClosureWithArg2(allowInterop(addXValues),
                  new ExampleLiteral(x: 20), new ExampleLiteral(x: 10))
              .x,
          equals(30));

      foo.x = 50;
      expect(
          foo
              .callClosureWithArgAndThis(allowInteropCaptureThis(addXValues),
                  new ExampleLiteral(x: 10))
              .x,
          equals(60));
    });

    test('call from dart', () {
      var returnNumArgsFn = returnNumArgs;
      var returnLastArgFn = returnLastArg;
      expect(returnNumArgsFn(), equals(0));
      expect(returnNumArgsFn("a", "b", "c"), equals(3));
      expect(returnNumArgsFn("a", "b", "c", null, null), equals(5));
      expect(returnNumArgsFn(1, 2, 3, 4, 5, 6, null), equals(7));
      expect(returnNumArgsFn(1, 2, 3, 4, 5, 6, 7, 8), equals(8));
      expect(returnLastArgFn(1, 2, "foo"), equals("foo"));
      expect(returnLastArgFn(1, 2, 3, 4, 5, 6, "foo"), equals("foo"));
    });
  });

  group('chain calls', () {
    test("method calls", () {
      // In dart2js make sure we still use interceptors when making nested
      // calls to objects.
      var bar = foo.getBar().getFoo().getBar().getFoo().getBar();
      expect(bar.x, equals("foo"));
    });
  });

  group('avoid leaks on dart core', () {
    test('String', () {
      var s = confuse('Hello');
      var stringWrapper = confuse(new StringWrapper('Hello'));
      // Make sure we don't allow calling JavaScript methods on String.
      expect(() => s.charCodeAt(0), throws);
      expect(stringWrapper.charCodeAt(0), equals(72));
    });
  });

  group(r'JS$ escaped', () {
    test('top level', () {
      expect(JS$class(), equals(42));
      expect(JS$delete, equals(100));
    });
    test('top level double escaped', () {
      expect(JS$JS$hasJsInName, equals('unicorn'));
      expect(JS$JS$hasJsInNameMethod(4), equals(20));
    });
  });

  group('type check', () {
    test('js interfaces', () {
      // Is checks return true for all  JavaScript interfaces.
      expect(foo is Bar, isTrue);
      expect(foo is Foob, isTrue);

      expect(selection is List, isTrue);

      // We do know at runtime whether something is a JsArray or not.
      expect(foo is List, isFalse);
    });

    test('dart interfaces', () {
      expect(foo is Function, isFalse);
      expect(selection is List, isTrue);
    });
  });
  group('html', () {
    test('return html type', () {
      expect(getCanvasContext() is CanvasRenderingContext2D, isTrue);
    });
    test('js path contains html types', () {
      expect(propertyOnWindow, equals(42));
      expect(propertyOnDocument, equals(45));
    });
  });
}
