dart_library.library('language/function_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_syntax_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_syntax_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.functionType(core.int, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.functionType(dart.dynamic, [dart.dynamic])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.functionType(dart.dynamic, [core.int])))();
  let JSArrayOfVoidToint = () => (JSArrayOfVoidToint = dart.constFn(_interceptors.JSArray$(VoidToint())))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic$ = () => (dynamicTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidToint$ = () => (VoidToint$ = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let dynamicAnddynamicToint = () => (dynamicAnddynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic, dart.dynamic])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let VoidToListOfint = () => (VoidToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [])))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodouble = () => (VoidTodouble = dart.constFn(dart.definiteFunctionType(core.double, [])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidTodynamic()])))();
  let FnTodynamic$ = () => (FnTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidToint()])))();
  let FnTodynamic$0 = () => (FnTodynamic$0 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dynamicTodynamic()])))();
  let FnTodynamic$1 = () => (FnTodynamic$1 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [intTodynamic()])))();
  function_syntax_test_none_multi.FunctionSyntaxTest = class FunctionSyntaxTest extends core.Object {
    static testMain() {
      function_syntax_test_none_multi.FunctionSyntaxTest.testNestedFunctions();
      function_syntax_test_none_multi.FunctionSyntaxTest.testFunctionExpressions();
      function_syntax_test_none_multi.FunctionSyntaxTest.testPrecedence();
      function_syntax_test_none_multi.FunctionSyntaxTest.testInitializers();
      function_syntax_test_none_multi.FunctionSyntaxTest.testFunctionParameter();
      function_syntax_test_none_multi.FunctionSyntaxTest.testFunctionIdentifierExpression();
      function_syntax_test_none_multi.FunctionSyntaxTest.testFunctionIdentifierStatement();
    }
    static testNestedFunctions() {
      function nb0() {
        return 42;
      }
      dart.fn(nb0, VoidTodynamic$());
      function nb1(a) {
        return a;
      }
      dart.fn(nb1, dynamicTodynamic$());
      function nb2(a, b) {
        return dart.dsend(a, '+', b);
      }
      dart.fn(nb2, dynamicAnddynamicTodynamic());
      expect$.Expect.equals(42, nb0());
      expect$.Expect.equals(87, nb1(87));
      expect$.Expect.equals(1 + 2, nb2(1, 2));
      function na0() {
        return 42;
      }
      dart.fn(na0, VoidTodynamic$());
      function na1(a) {
        return a;
      }
      dart.fn(na1, dynamicTodynamic$());
      function na2(a, b) {
        return dart.dsend(a, '+', b);
      }
      dart.fn(na2, dynamicAnddynamicTodynamic());
      expect$.Expect.equals(42, na0());
      expect$.Expect.equals(87, na1(87));
      expect$.Expect.equals(1 + 2, na2(1, 2));
      function rb0() {
        return 42;
      }
      dart.fn(rb0, VoidToint$());
      function rb1(a) {
        return core.int._check(a);
      }
      dart.fn(rb1, dynamicToint());
      function rb2(a, b) {
        return core.int._check(dart.dsend(a, '+', b));
      }
      dart.fn(rb2, dynamicAnddynamicToint());
      expect$.Expect.equals(42, rb0());
      expect$.Expect.equals(87, rb1(87));
      expect$.Expect.equals(1 + 2, rb2(1, 2));
      function ra0() {
        return 42;
      }
      dart.fn(ra0, VoidToint$());
      function ra1(a) {
        return core.int._check(a);
      }
      dart.fn(ra1, dynamicToint());
      function ra2(a, b) {
        return core.int._check(dart.dsend(a, '+', b));
      }
      dart.fn(ra2, dynamicAnddynamicToint());
      expect$.Expect.equals(42, ra0());
      expect$.Expect.equals(87, ra1(87));
      expect$.Expect.equals(1 + 2, ra2(1, 2));
      function fb1(a) {
        return a;
      }
      dart.fn(fb1, intToint());
      function fb2(a, b) {
        return dart.notNull(a) + dart.notNull(b);
      }
      dart.fn(fb2, intAndintToint());
      expect$.Expect.equals(42, rb0());
      expect$.Expect.equals(87, rb1(87));
      expect$.Expect.equals(1 + 2, rb2(1, 2));
      function fa1(a) {
        return a;
      }
      dart.fn(fa1, intToint());
      function fa2(a, b) {
        return dart.notNull(a) + dart.notNull(b);
      }
      dart.fn(fa2, intAndintToint());
      expect$.Expect.equals(42, ra0());
      expect$.Expect.equals(87, ra1(87));
      expect$.Expect.equals(1 + 2, ra2(1, 2));
      function gb0() {
        return JSArrayOfint().of([42]);
      }
      dart.fn(gb0, VoidToListOfint());
      function gb1(a) {
        return a;
      }
      dart.fn(gb1, ListOfintToListOfint());
      expect$.Expect.equals(42, gb0()[dartx.get](0));
      expect$.Expect.equals(87, gb1(JSArrayOfint().of([87]))[dartx.get](0));
      function ga0() {
        return JSArrayOfint().of([42]);
      }
      dart.fn(ga0, VoidToListOfint());
      function ga1(a) {
        return a;
      }
      dart.fn(ga1, ListOfintToListOfint());
      expect$.Expect.equals(42, ga0()[dartx.get](0));
      expect$.Expect.equals(87, ga1(JSArrayOfint().of([87]))[dartx.get](0));
    }
    static testFunctionExpressions() {
      function eval0(fn) {
        return dart.dcall(fn);
      }
      dart.fn(eval0, dynamicTodynamic$());
      function eval1(fn, a) {
        return dart.dcall(fn, a);
      }
      dart.fn(eval1, dynamicAnddynamicTodynamic());
      function eval2(fn, a, b) {
        return dart.dcall(fn, a, b);
      }
      dart.fn(eval2, dynamicAnddynamicAnddynamicTodynamic());
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, dynamicTodynamic$()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, dynamicTodynamic$()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, dynamicTodynamic$()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, dynamicTodynamic$()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, intToint()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.notNull(a) + dart.notNull(b), intAndintToint()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, intToint()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.notNull(a) + dart.notNull(b), intAndintToint()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, intToint()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.notNull(a) + dart.notNull(b), intAndintToint()), 1, 2));
      expect$.Expect.equals(42, eval0(dart.fn(() => 42, VoidToint$())));
      expect$.Expect.equals(87, eval1(dart.fn(a => a, intToint()), 87));
      expect$.Expect.equals(1 + 2, eval2(dart.fn((a, b) => dart.notNull(a) + dart.notNull(b), intAndintToint()), 1, 2));
    }
    static testPrecedence() {
      function expectEvaluatesTo(value, fn) {
        expect$.Expect.equals(value, dart.dcall(fn));
      }
      dart.fn(expectEvaluatesTo, dynamicAnddynamicTodynamic());
      let x = null;
      expectEvaluatesTo(42, dart.fn(() => x = 42, VoidToint$()));
      expect$.Expect.equals(42, x);
      x = 1;
      expectEvaluatesTo(100, dart.fn(() => (x = dart.dsend(x, '+', 99)), VoidTodynamic$()));
      expect$.Expect.equals(100, x);
      x = 1;
      expectEvaluatesTo(87, dart.fn(() => (x = dart.dsend(x, '*', 87)), VoidTodynamic$()));
      expect$.Expect.equals(87, x);
      expectEvaluatesTo(42, dart.fn(() => true ? 42 : 87, VoidToint$()));
      expectEvaluatesTo(87, dart.fn(() => false ? 42 : 87, VoidToint$()));
      expectEvaluatesTo(true, dart.fn(() => true || true, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => true || false, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => false || true, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => false || false, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => true && true, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => true && false, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => false && true, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => false && false, VoidTobool()));
      expectEvaluatesTo(3, dart.fn(() => 1 | 2, VoidToint$()));
      expectEvaluatesTo(2, dart.fn(() => 3 ^ 1, VoidToint$()));
      expectEvaluatesTo(1, dart.fn(() => 3 & 1, VoidToint$()));
      expectEvaluatesTo(true, dart.fn(() => 1 == 1, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => 1 != 1, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => core.identical(1, 1), VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => !core.identical(1, 1), VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => 1 <= 1, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => 1 < 1, VoidTobool()));
      expectEvaluatesTo(false, dart.fn(() => 1 > 1, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => 1 >= 1, VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => typeof 1 == 'number', VoidTobool()));
      expectEvaluatesTo(true, dart.fn(() => typeof 1.0 == 'number', VoidTobool()));
      expectEvaluatesTo(2, dart.fn(() => 1 << 1, VoidToint$()));
      expectEvaluatesTo(1, dart.fn(() => 2 >> 1, VoidToint$()));
      expectEvaluatesTo(2, dart.fn(() => 1 + 1, VoidToint$()));
      expectEvaluatesTo(1, dart.fn(() => 2 - 1, VoidToint$()));
      expectEvaluatesTo(2, dart.fn(() => 1 * 2, VoidToint$()));
      expectEvaluatesTo(2.0, dart.fn(() => 4 / 2, VoidTodouble()));
      expectEvaluatesTo(2, dart.fn(() => (4 / 2)[dartx.truncate](), VoidToint$()));
      expectEvaluatesTo(0, dart.fn(() => (4)[dartx['%']](2), VoidToint$()));
      expectEvaluatesTo(false, dart.fn(() => !true, VoidTobool()));
      let y = 0;
      expectEvaluatesTo(0, dart.fn(() => y++, VoidToint$()));
      expectEvaluatesTo(2, dart.fn(() => ++y, VoidToint$()));
      expectEvaluatesTo(1, dart.fn(() => --y, VoidToint$()));
      expectEvaluatesTo(1, dart.fn(() => y--, VoidToint$()));
      expect$.Expect.equals(0, y);
      function fn() {
        return 42;
      }
      dart.fn(fn, VoidTodynamic$());
      let list = JSArrayOfint().of([87]);
      expectEvaluatesTo(42, dart.fn(() => fn(), VoidTodynamic$()));
      expectEvaluatesTo(1, dart.fn(() => list[dartx.length], VoidToint$()));
      expectEvaluatesTo(87, dart.fn(() => list[dartx.get](0), VoidToint$()));
      expectEvaluatesTo(87, dart.fn(() => list[dartx.removeLast](), VoidToint$()));
    }
    static testInitializers() {
      expect$.Expect.equals(42, dart.dcall(new function_syntax_test_none_multi.C.cb0().fn));
      expect$.Expect.equals(43, dart.dcall(new function_syntax_test_none_multi.C.ca0().fn));
      expect$.Expect.equals(44, dart.dcall(new function_syntax_test_none_multi.C.cb1().fn));
      expect$.Expect.equals(45, dart.dcall(new function_syntax_test_none_multi.C.ca1().fn));
      expect$.Expect.equals(46, dart.dcall(new function_syntax_test_none_multi.C.cb2().fn));
      expect$.Expect.equals(47, dart.dcall(new function_syntax_test_none_multi.C.ca2().fn));
      expect$.Expect.equals(48, dart.dcall(new function_syntax_test_none_multi.C.cb3().fn));
      expect$.Expect.equals(49, dart.dcall(new function_syntax_test_none_multi.C.ca3().fn));
      expect$.Expect.equals(52, dart.dcall(new function_syntax_test_none_multi.C.nb0().fn));
      expect$.Expect.equals(53, dart.dcall(new function_syntax_test_none_multi.C.na0().fn));
      expect$.Expect.equals(54, dart.dcall(new function_syntax_test_none_multi.C.nb1().fn));
      expect$.Expect.equals(55, dart.dcall(new function_syntax_test_none_multi.C.na1().fn));
      expect$.Expect.equals(56, dart.dcall(new function_syntax_test_none_multi.C.nb2().fn));
      expect$.Expect.equals(57, dart.dcall(new function_syntax_test_none_multi.C.na2().fn));
      expect$.Expect.equals(58, dart.dcall(new function_syntax_test_none_multi.C.nb3().fn));
      expect$.Expect.equals(59, dart.dcall(new function_syntax_test_none_multi.C.na3().fn));
      expect$.Expect.equals(62, dart.dcall(new function_syntax_test_none_multi.C.rb0().fn));
      expect$.Expect.equals(63, dart.dcall(new function_syntax_test_none_multi.C.ra0().fn));
      expect$.Expect.equals(64, dart.dcall(new function_syntax_test_none_multi.C.rb1().fn));
      expect$.Expect.equals(65, dart.dcall(new function_syntax_test_none_multi.C.ra1().fn));
      expect$.Expect.equals(66, dart.dcall(new function_syntax_test_none_multi.C.rb2().fn));
      expect$.Expect.equals(67, dart.dcall(new function_syntax_test_none_multi.C.ra2().fn));
      expect$.Expect.equals(68, dart.dcall(new function_syntax_test_none_multi.C.rb3().fn));
      expect$.Expect.equals(69, dart.dcall(new function_syntax_test_none_multi.C.ra3().fn));
    }
    static testFunctionParameter() {
      function f0(fn) {
        return fn();
      }
      dart.fn(f0, FnTodynamic());
      expect$.Expect.equals(42, f0(dart.fn(() => 42, VoidToint$())));
      function f1(fn) {
        return fn();
      }
      dart.fn(f1, FnTodynamic$());
      expect$.Expect.equals(87, f1(dart.fn(() => 87, VoidToint$())));
      function f2(fn) {
        return dart.dcall(fn, 42);
      }
      dart.fn(f2, FnTodynamic$0());
      expect$.Expect.equals(43, f2(dart.fn(a => dart.dsend(a, '+', 1), dynamicTodynamic$())));
      function f3(fn) {
        return fn(42);
      }
      dart.fn(f3, FnTodynamic$1());
      expect$.Expect.equals(44, f3(dart.fn(a => dart.notNull(a) + 2, intToint())));
    }
    static testFunctionIdentifierExpression() {
      expect$.Expect.equals(87, dart.fn(() => 87, VoidToint$())());
    }
    static testFunctionIdentifierStatement() {
      function func() {
        return 42;
      }
      dart.fn(func, VoidTodynamic$());
      expect$.Expect.equals(42, func());
      expect$.Expect.equals(true, core.Function.is(func));
    }
  };
  dart.setSignature(function_syntax_test_none_multi.FunctionSyntaxTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.void, []),
      testNestedFunctions: dart.definiteFunctionType(dart.void, []),
      testFunctionExpressions: dart.definiteFunctionType(dart.void, []),
      testPrecedence: dart.definiteFunctionType(dart.void, []),
      testInitializers: dart.definiteFunctionType(dart.void, []),
      testFunctionParameter: dart.definiteFunctionType(dart.void, []),
      testFunctionIdentifierExpression: dart.definiteFunctionType(dart.void, []),
      testFunctionIdentifierStatement: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testMain', 'testNestedFunctions', 'testFunctionExpressions', 'testPrecedence', 'testInitializers', 'testFunctionParameter', 'testFunctionIdentifierExpression', 'testFunctionIdentifierStatement']
  });
  function_syntax_test_none_multi.C = class C extends core.Object {
    cb0() {
      this.fn = dart.fn(() => 42, VoidToint$());
    }
    ca0() {
      this.fn = dart.fn(() => 43, VoidToint$());
    }
    cb1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 44, VoidToint$()));
    }
    ca1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 45, VoidToint$()));
    }
    cb2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 46, VoidToint$())])[dartx.get](0);
    }
    ca2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 47, VoidToint$())])[dartx.get](0);
    }
    cb3() {
      this.fn = dart.map({x: dart.fn(() => 48, VoidToint$())})[dartx.get]('x');
    }
    ca3() {
      this.fn = dart.map({x: dart.fn(() => 49, VoidToint$())})[dartx.get]('x');
    }
    nb0() {
      this.fn = dart.fn(() => 52, VoidToint$());
    }
    na0() {
      this.fn = dart.fn(() => 53, VoidToint$());
    }
    nb1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 54, VoidToint$()));
    }
    na1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 55, VoidToint$()));
    }
    nb2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 56, VoidToint$())])[dartx.get](0);
    }
    na2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 57, VoidToint$())])[dartx.get](0);
    }
    nb3() {
      this.fn = dart.map({x: dart.fn(() => 58, VoidToint$())})[dartx.get]('x');
    }
    na3() {
      this.fn = dart.map({x: dart.fn(() => 59, VoidToint$())})[dartx.get]('x');
    }
    rb0() {
      this.fn = dart.fn(() => 62, VoidToint$());
    }
    ra0() {
      this.fn = dart.fn(() => 63, VoidToint$());
    }
    rb1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 64, VoidToint$()));
    }
    ra1() {
      this.fn = function_syntax_test_none_multi.C.wrap(dart.fn(() => 65, VoidToint$()));
    }
    rb2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 66, VoidToint$())])[dartx.get](0);
    }
    ra2() {
      this.fn = JSArrayOfVoidToint().of([dart.fn(() => 67, VoidToint$())])[dartx.get](0);
    }
    rb3() {
      this.fn = dart.map({x: dart.fn(() => 68, VoidToint$())})[dartx.get]('x');
    }
    ra3() {
      this.fn = dart.map({x: dart.fn(() => 69, VoidToint$())})[dartx.get]('x');
    }
    static wrap(fn) {
      return fn;
    }
  };
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'cb0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ca0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'cb1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ca1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'cb2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ca2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'cb3');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ca3');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'nb0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'na0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'nb1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'na1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'nb2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'na2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'nb3');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'na3');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'rb0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ra0');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'rb1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ra1');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'rb2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ra2');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'rb3');
  dart.defineNamedConstructor(function_syntax_test_none_multi.C, 'ra3');
  dart.setSignature(function_syntax_test_none_multi.C, {
    constructors: () => ({
      cb0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ca0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      cb1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ca1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      cb2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ca2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      cb3: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ca3: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      nb0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      na0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      nb1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      na1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      nb2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      na2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      nb3: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      na3: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      rb0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ra0: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      rb1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ra1: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      rb2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ra2: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      rb3: dart.definiteFunctionType(function_syntax_test_none_multi.C, []),
      ra3: dart.definiteFunctionType(function_syntax_test_none_multi.C, [])
    }),
    statics: () => ({wrap: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    names: ['wrap']
  });
  function_syntax_test_none_multi.main = function() {
    function_syntax_test_none_multi.FunctionSyntaxTest.testMain();
  };
  dart.fn(function_syntax_test_none_multi.main, VoidTodynamic$());
  // Exports:
  exports.function_syntax_test_none_multi = function_syntax_test_none_multi;
});
