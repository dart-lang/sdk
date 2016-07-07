dart_library.library('lib/html/js_typed_interop_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__js_typed_interop_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const js = dart_sdk.js;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const js_typed_interop_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let dynamicAndExampleLiteralToExampleLiteral = () => (dynamicAndExampleLiteralToExampleLiteral = dart.constFn(dart.functionType(dart.global.ExampleLiteral, [dart.dynamic, dart.global.ExampleLiteral])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamic__Todynamic$ = () => (dynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let FooAndintTodynamic = () => (FooAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.global.Foo, core.int])))();
  let dynamicAndExampleLiteralToExampleLiteral$ = () => (dynamicAndExampleLiteralToExampleLiteral$ = dart.constFn(dart.definiteFunctionType(dart.global.ExampleLiteral, [dart.dynamic, dart.global.ExampleLiteral])))();
  js_typed_interop_test._injectJs = function() {
    html.document[dartx.body][dartx.append]((() => {
      let _ = html.ScriptElement.new();
      _[dartx.type] = 'text/javascript';
      _[dartx.innerHtml] = "  var Foo = {\n    multiplyDefault2: function(a, b) {\n      if (arguments.length >= 2) return a *b;\n      return a * 2;\n    }\n  };\n\n  var foo = {\n    x: 3,\n    z: 40, // Not specified in typed Dart API so should fail in checked mode.\n    multiplyByX: function(arg) { return arg * this.x; },\n    // This function can be torn off without having to bind this.\n    multiplyBy2: function(arg) { return arg * 2; },\n    multiplyDefault2Function: function(a, b) {\n      if (arguments.length >= 2) return a * b;\n      return a * 2;\n    },\n    callClosureWithArg1: function(closure, arg) {\n      return closure(arg);\n    },\n    callClosureWithArg2: function(closure, arg1, arg2) {\n      return closure(arg1, arg2);\n    },\n    callClosureWithArgAndThis: function(closure, arg) {\n      return closure.apply(this, [arg]);\n    },\n\n    getBar: function() {\n      return bar;\n    }\n  };\n\n  var foob = {\n    x: 8,\n    y: \"why\",\n    multiplyByX: function(arg) { return arg * this.x; }\n  };\n\n  var bar = {\n    x: \"foo\",\n    multiplyByX: true,\n    getFoo: function() {\n      return foo;\n    }\n  };\n\n  function ClassWithConstructor(a, b) {\n    this.a = a;\n    this.b = b;\n  };\n\n  ClassWithConstructor.prototype = {\n    getA: function() { return this.a;}\n  };\n\n  var selection = [\"a\", \"b\", \"c\", foo, bar];  \n\n  function returnNumArgs() { return arguments.length; };\n  function returnLastArg() { return arguments[arguments.length-1]; };\n\n  function confuse(obj) { return obj; }\n\n  function StringWrapper(str) {\n    this.str = str;\n  }\n  StringWrapper.prototype = {\n    charCodeAt: function(index) {\n      return this.str.charCodeAt(index);\n    }\n  };\n  function getCanvasContext() {\n    return document.createElement('canvas').getContext('2d');\n  }\n  window.windowProperty = 42;\n  document.documentProperty = 45;\n";
      return _;
    })());
  };
  dart.fn(js_typed_interop_test._injectJs, VoidTodynamic());
  js_typed_interop_test.RegularClass = class RegularClass extends core.Object {
    static new(a) {
      return new js_typed_interop_test.RegularClass.fooConstructor(a);
    }
    fooConstructor(a) {
      this.a = a;
    }
  };
  dart.defineNamedConstructor(js_typed_interop_test.RegularClass, 'fooConstructor');
  dart.setSignature(js_typed_interop_test.RegularClass, {
    constructors: () => ({
      new: dart.definiteFunctionType(js_typed_interop_test.RegularClass, [dart.dynamic]),
      fooConstructor: dart.definiteFunctionType(js_typed_interop_test.RegularClass, [dart.dynamic])
    })
  });
  js_typed_interop_test.MultiplyWithDefault = dart.typedef('MultiplyWithDefault', () => dart.functionType(core.num, [core.num], [core.num]));
  js_typed_interop_test.addWithDefault = function(a, b) {
    if (b === void 0) b = 100;
    return dart.dsend(a, '+', b);
  };
  dart.fn(js_typed_interop_test.addWithDefault, dynamic__Todynamic$());
  js_typed_interop_test.STRINGIFY_LOCATION = "JSON.stringify";
  js_typed_interop_test.main = function() {
    js_typed_interop_test._injectJs();
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('object literal', dart.fn(() => {
      unittest$.test('simple', dart.fn(() => {
        let l = {x: 3, y: "foo"};
        src__matcher__expect.expect(l.x, src__matcher__core_matchers.equals(3));
        src__matcher__expect.expect(l.y, src__matcher__core_matchers.equals("foo"));
        src__matcher__expect.expect(l.z, src__matcher__core_matchers.isNull);
        src__matcher__expect.expect(dart.global.JSON.stringify(l), src__matcher__core_matchers.equals('{"x":3,"y":"foo"}'));
        l = {z: 100};
        src__matcher__expect.expect(l.x, src__matcher__core_matchers.isNull);
        src__matcher__expect.expect(l.y, src__matcher__core_matchers.isNull);
        src__matcher__expect.expect(l.z, src__matcher__core_matchers.equals(100));
        src__matcher__expect.expect(dart.global.JSON.stringify(l), src__matcher__core_matchers.equals('{"z":100}'));
      }, VoidTodynamic()));
      unittest$.test('empty', dart.fn(() => {
        let l = {};
        src__matcher__expect.expect(dart.global.JSON.stringify(l), src__matcher__core_matchers.equals('{}'));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructor', dart.fn(() => {
      unittest$.test('simple', dart.fn(() => {
        let o = new dart.global.ClassWithConstructor("foo", "bar");
        src__matcher__expect.expect(o.a, src__matcher__core_matchers.equals("foo"));
        src__matcher__expect.expect(o.b, src__matcher__core_matchers.equals("bar"));
        src__matcher__expect.expect(o.getA(), src__matcher__core_matchers.equals("foo"));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('property', dart.fn(() => {
      unittest$.test('get', dart.fn(() => {
        src__matcher__expect.expect(dart.global.foo.x, src__matcher__core_matchers.equals(3));
        src__matcher__expect.expect(dart.global.foob.x, src__matcher__core_matchers.equals(8));
        src__matcher__expect.expect(dart.global.foob.y, src__matcher__core_matchers.equals("why"));
        src__matcher__expect.expect(dart.fn(() => dart.dload(dart.global.foo, 'zSomeInvalidName'), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.global.bar.multiplyByX, src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
      unittest$.test('set', dart.fn(() => {
        dart.global.foo.x = 42;
        src__matcher__expect.expect(dart.global.foo.x, src__matcher__core_matchers.equals(42));
        src__matcher__expect.expect(dart.fn(() => dart.dput(dart.global.foob, 'y', "bla"), VoidToString()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.fn(() => dart.dput(dart.global.foo, 'unknownName', 42), VoidToint()), src__matcher__throws_matcher.throws);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('method', dart.fn(() => {
      unittest$.test('call', dart.fn(() => {
        dart.global.foo.x = 100;
        src__matcher__expect.expect(dart.global.foo.multiplyByX(4), src__matcher__core_matchers.equals(400));
        dart.global.foob.x = 10;
        src__matcher__expect.expect(dart.global.foob.multiplyByX(4), src__matcher__core_matchers.equals(40));
      }, VoidTodynamic()));
      unittest$.test('tearoff', dart.fn(() => {
        dart.global.foo.x = 10;
        let multiplyBy2 = dart.bind(dart.global.foo, 'multiplyBy2');
        src__matcher__expect.expect(dart.dcall(multiplyBy2, 5), src__matcher__core_matchers.equals(10));
        let multiplyByX = dart.bind(dart.global.foo, 'multiplyByX');
        src__matcher__expect.expect(dart.dcall(multiplyByX, 4), src__matcher__core_matchers.isNaN);
        let multiplyWithDefault = dart.global.foo.multiplyDefault2Function;
        src__matcher__expect.expect(multiplyWithDefault(6, 6), src__matcher__core_matchers.equals(36));
        src__matcher__expect.expect(multiplyWithDefault(6), src__matcher__core_matchers.equals(12));
        let untypedFunction = dart.global.foo.multiplyDefault2Function;
        src__matcher__expect.expect(dart.dcall(untypedFunction, 6, 6, "ignored", "ignored"), src__matcher__core_matchers.equals(36));
        src__matcher__expect.expect(dart.dcall(untypedFunction, 6, 6, "ignored", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), src__matcher__core_matchers.equals(36));
        src__matcher__expect.expect(dart.dcall(untypedFunction), src__matcher__core_matchers.isNaN);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('static_method_call', dart.fn(() => {
      unittest$.test('call directly from dart', dart.fn(() => {
        src__matcher__expect.expect(dart.global.Foo.multiplyDefault2(6, 7), src__matcher__core_matchers.equals(42));
        src__matcher__expect.expect(dart.global.Foo.multiplyDefault2(6), src__matcher__core_matchers.equals(12));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('static_method_tearoff_1', dart.fn(() => {
      unittest$.test('call tearoff from dart', dart.fn(() => {
        let tearOffMethod = dart.global.Foo.multiplyDefault2;
        src__matcher__expect.expect(tearOffMethod(6, 6), src__matcher__core_matchers.equals(36));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('static_method_tearoff_2', dart.fn(() => {
      unittest$.test('call tearoff from dart', dart.fn(() => {
        let tearOffMethod = dart.global.Foo.multiplyDefault2;
        src__matcher__expect.expect(tearOffMethod(6), src__matcher__core_matchers.equals(12));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('closure', dart.fn(() => {
      unittest$.test('call from js', dart.fn(() => {
        function localClosure(x) {
          return dart.dsend(x, '*', 10);
        }
        dart.fn(localClosure, dynamicTodynamic$());
        let wrappedLocalClosure = js.allowInterop(dynamicTodynamic())(localClosure);
        src__matcher__expect.expect(core.identical(js.allowInterop(dynamicTodynamic())(localClosure), wrappedLocalClosure), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(dart.global.foo.callClosureWithArg1(wrappedLocalClosure, 10), src__matcher__core_matchers.equals(100));
        src__matcher__expect.expect(dart.global.foo.callClosureWithArg1(wrappedLocalClosure, "a"), src__matcher__core_matchers.equals("aaaaaaaaaa"));
        src__matcher__expect.expect(dart.global.foo.callClosureWithArg1(js.allowInterop(dynamic__Todynamic())(js_typed_interop_test.addWithDefault), 10), src__matcher__core_matchers.equals(110));
        src__matcher__expect.expect(dart.global.foo.callClosureWithArg2(js.allowInterop(dynamic__Todynamic())(js_typed_interop_test.addWithDefault), 10, 20), src__matcher__core_matchers.equals(30));
        function addThisXAndArg(that, arg) {
          return dart.notNull(dart.global.foo.x) + dart.notNull(arg);
        }
        dart.fn(addThisXAndArg, FooAndintTodynamic());
        let wrappedCaptureThisClosure = js.allowInteropCaptureThis(addThisXAndArg);
        dart.global.foo.x = 20;
        src__matcher__expect.expect(dart.global.foo.callClosureWithArgAndThis(wrappedCaptureThisClosure, 10), src__matcher__core_matchers.equals(30));
        dart.global.foo.x = 50;
        src__matcher__expect.expect(dart.global.foo.callClosureWithArgAndThis(wrappedCaptureThisClosure, 10), src__matcher__core_matchers.equals(60));
        src__matcher__expect.expect(core.identical(js.allowInteropCaptureThis(addThisXAndArg), wrappedCaptureThisClosure), src__matcher__core_matchers.isTrue);
        function addXValues(that, arg) {
          return {x: core.int._check(dart.dsend(dart.dload(that, 'x'), '+', arg.x))};
        }
        dart.fn(addXValues, dynamicAndExampleLiteralToExampleLiteral$());
        src__matcher__expect.expect(dart.dload(dart.global.foo.callClosureWithArg2(js.allowInterop(dynamicAndExampleLiteralToExampleLiteral())(addXValues), {x: 20}, {x: 10}), 'x'), src__matcher__core_matchers.equals(30));
        dart.global.foo.x = 50;
        src__matcher__expect.expect(dart.dload(dart.global.foo.callClosureWithArgAndThis(js.allowInteropCaptureThis(addXValues), {x: 10}), 'x'), src__matcher__core_matchers.equals(60));
      }, VoidTodynamic()));
      unittest$.test('call from dart', dart.fn(() => {
        let returnNumArgsFn = dart.global.returnNumArgs;
        let returnLastArgFn = dart.global.returnLastArg;
        src__matcher__expect.expect(dart.dcall(returnNumArgsFn), src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(dart.dcall(returnNumArgsFn, "a", "b", "c"), src__matcher__core_matchers.equals(3));
        src__matcher__expect.expect(dart.dcall(returnNumArgsFn, "a", "b", "c", null, null), src__matcher__core_matchers.equals(5));
        src__matcher__expect.expect(dart.dcall(returnNumArgsFn, 1, 2, 3, 4, 5, 6, null), src__matcher__core_matchers.equals(7));
        src__matcher__expect.expect(dart.dcall(returnNumArgsFn, 1, 2, 3, 4, 5, 6, 7, 8), src__matcher__core_matchers.equals(8));
        src__matcher__expect.expect(dart.dcall(returnLastArgFn, 1, 2, "foo"), src__matcher__core_matchers.equals("foo"));
        src__matcher__expect.expect(dart.dcall(returnLastArgFn, 1, 2, 3, 4, 5, 6, "foo"), src__matcher__core_matchers.equals("foo"));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('chain calls', dart.fn(() => {
      unittest$.test("method calls", dart.fn(() => {
        let bar = dart.global.foo.getBar().getFoo().getBar().getFoo().getBar();
        src__matcher__expect.expect(bar.x, src__matcher__core_matchers.equals("foo"));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('avoid leaks on dart:core', dart.fn(() => {
      unittest$.test('String', dart.fn(() => {
        let s = dart.global.confuse('Hello');
        let stringWrapper = dart.global.confuse(new dart.global.StringWrapper('Hello'));
        src__matcher__expect.expect(dart.fn(() => dart.dsend(s, 'charCodeAt', 0), VoidTodynamic()), src__matcher__throws_matcher.throws);
        src__matcher__expect.expect(dart.dsend(stringWrapper, 'charCodeAt', 0), src__matcher__core_matchers.equals(72));
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('type check', dart.fn(() => {
      unittest$.test('js interfaces', dart.fn(() => {
        src__matcher__expect.expect(dart.global.Bar.is(dart.global.foo), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(dart.global.Foob.is(dart.global.foo), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(core.List.is(dart.global.selection), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(core.List.is(dart.global.foo), src__matcher__core_matchers.isFalse);
      }, VoidTodynamic()));
      unittest$.test('dart interfaces', dart.fn(() => {
        src__matcher__expect.expect(core.Function.is(dart.global.foo), src__matcher__core_matchers.isFalse);
        src__matcher__expect.expect(core.List.is(dart.global.selection), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('html', dart.fn(() => {
      unittest$.test('return html type', dart.fn(() => {
        src__matcher__expect.expect(html.CanvasRenderingContext2D.is(dart.global.getCanvasContext()), src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
      unittest$.test('js path contains html types', dart.fn(() => {
        src__matcher__expect.expect(dart.global.window.self.window.window.windowProperty, src__matcher__core_matchers.equals(42));
        src__matcher__expect.expect(dart.global.window.window.document.documentProperty, src__matcher__core_matchers.equals(45));
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(js_typed_interop_test.main, VoidTodynamic());
  // Exports:
  exports.js_typed_interop_test = js_typed_interop_test;
});
