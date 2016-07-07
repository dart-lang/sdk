dart_library.library('language/typedef_is_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typedef_is_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typedef_is_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let intAndintAndintToint = () => (intAndintAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int, core.int])))();
  let int__Toint = () => (int__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.int], [core.int])))();
  let int__Toint$ = () => (int__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.int], [core.int, core.int])))();
  let __Toint = () => (__Toint = dart.constFn(dart.definiteFunctionType(core.int, [], [core.int, core.int, core.int])))();
  let int__Toint$0 = () => (int__Toint$0 = dart.constFn(dart.definiteFunctionType(core.int, [core.int], {j: core.int})))();
  let int__Toint$1 = () => (int__Toint$1 = dart.constFn(dart.definiteFunctionType(core.int, [core.int], {b: core.int})))();
  let int__Toint$2 = () => (int__Toint$2 = dart.constFn(dart.definiteFunctionType(core.int, [core.int], {b: core.int, c: core.int})))();
  let int__Toint$3 = () => (int__Toint$3 = dart.constFn(dart.definiteFunctionType(core.int, [core.int], {c: core.int, b: core.int})))();
  let __Toint$ = () => (__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [], {a: core.int, b: core.int, c: core.int})))();
  let __Toint$0 = () => (__Toint$0 = dart.constFn(dart.definiteFunctionType(core.int, [], {c: core.int, a: core.int, b: core.int})))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  typedef_is_test.Func1 = dart.typedef('Func1', () => dart.functionType(core.int, [core.int]));
  typedef_is_test.Func2 = dart.typedef('Func2', () => dart.functionType(core.int, [core.int], [core.int]));
  typedef_is_test.Func3 = dart.typedef('Func3', () => dart.functionType(core.int, [core.int], [core.int, core.int]));
  typedef_is_test.Func4 = dart.typedef('Func4', () => dart.functionType(core.int, [], [core.int, core.int, core.int]));
  typedef_is_test.Func5 = dart.typedef('Func5', () => dart.functionType(core.int, [core.int], {b: core.int}));
  typedef_is_test.Func6 = dart.typedef('Func6', () => dart.functionType(core.int, [core.int], {b: core.int, c: core.int}));
  typedef_is_test.Func7 = dart.typedef('Func7', () => dart.functionType(core.int, [], {a: core.int, b: core.int, c: core.int}));
  typedef_is_test.main = function() {
    function func1(i) {
    }
    dart.fn(func1, intToint());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func1));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func1));
    function func2(i, j) {
    }
    dart.fn(func2, intAndintToint());
    expect$.Expect.isFalse(typedef_is_test.Func1.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func2));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func2));
    function func3(i, j, k) {
    }
    dart.fn(func3, intAndintAndintToint());
    expect$.Expect.isFalse(typedef_is_test.Func1.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func3));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func3));
    function func4(i, j) {
      if (j === void 0) j = null;
    }
    dart.fn(func4, int__Toint());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func4));
    expect$.Expect.isTrue(typedef_is_test.Func2.is(func4));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func4));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func4));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func4));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func4));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func4));
    function func5(i, j, k) {
      if (j === void 0) j = null;
      if (k === void 0) k = null;
    }
    dart.fn(func5, int__Toint$());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func5));
    expect$.Expect.isTrue(typedef_is_test.Func2.is(func5));
    expect$.Expect.isTrue(typedef_is_test.Func3.is(func5));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func5));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func5));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func5));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func5));
    function func6(i, j, k) {
      if (i === void 0) i = null;
      if (j === void 0) j = null;
      if (k === void 0) k = null;
    }
    dart.fn(func6, __Toint());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func6));
    expect$.Expect.isTrue(typedef_is_test.Func2.is(func6));
    expect$.Expect.isTrue(typedef_is_test.Func3.is(func6));
    expect$.Expect.isTrue(typedef_is_test.Func4.is(func6));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func6));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func6));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func6));
    function func7(i, opts) {
      let j = opts && 'j' in opts ? opts.j : null;
    }
    dart.fn(func7, int__Toint$0());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func7));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func7));
    function func8(i, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
    }
    dart.fn(func8, int__Toint$1());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func8));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func8));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func8));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func8));
    expect$.Expect.isTrue(typedef_is_test.Func5.is(func8));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func8));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func8));
    function func9(i, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      let c = opts && 'c' in opts ? opts.c : null;
    }
    dart.fn(func9, int__Toint$2());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func9));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func9));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func9));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func9));
    expect$.Expect.isTrue(typedef_is_test.Func5.is(func9));
    expect$.Expect.isTrue(typedef_is_test.Func6.is(func9));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func9));
    function func10(i, opts) {
      let c = opts && 'c' in opts ? opts.c : null;
      let b = opts && 'b' in opts ? opts.b : null;
    }
    dart.fn(func10, int__Toint$3());
    expect$.Expect.isTrue(typedef_is_test.Func1.is(func10));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func10));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func10));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func10));
    expect$.Expect.isTrue(typedef_is_test.Func5.is(func10));
    expect$.Expect.isTrue(typedef_is_test.Func6.is(func10));
    expect$.Expect.isFalse(typedef_is_test.Func7.is(func10));
    function func11(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      let c = opts && 'c' in opts ? opts.c : null;
    }
    dart.fn(func11, __Toint$());
    expect$.Expect.isFalse(typedef_is_test.Func1.is(func11));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func11));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func11));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func11));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func11));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func11));
    expect$.Expect.isTrue(typedef_is_test.Func7.is(func11));
    function func12(opts) {
      let c = opts && 'c' in opts ? opts.c : null;
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
    }
    dart.fn(func12, __Toint$0());
    expect$.Expect.isFalse(typedef_is_test.Func1.is(func12));
    expect$.Expect.isFalse(typedef_is_test.Func2.is(func12));
    expect$.Expect.isFalse(typedef_is_test.Func3.is(func12));
    expect$.Expect.isFalse(typedef_is_test.Func4.is(func12));
    expect$.Expect.isFalse(typedef_is_test.Func5.is(func12));
    expect$.Expect.isFalse(typedef_is_test.Func6.is(func12));
    expect$.Expect.isTrue(typedef_is_test.Func7.is(func12));
  };
  dart.fn(typedef_is_test.main, VoidTovoid());
  // Exports:
  exports.typedef_is_test = typedef_is_test;
});
