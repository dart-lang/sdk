dart_library.library('language/async_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__async_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_test = Object.create(null);
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intToFutureOfint = () => (intToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [core.int])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let ATovoid = () => (ATovoid = dart.constFn(dart.definiteFunctionType(dart.void, [async_test.A])))();
  let intAnddynamicTodynamic = () => (intAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, dart.dynamic])))();
  let intAndStringAndnumTodynamic = () => (intAndStringAndnumTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, core.String, core.num])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToFutureOfint = () => (VoidToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [])))();
  async_test.topLevelFunction = function() {
    return dart.async(function*() {
    }, dart.dynamic);
  };
  dart.fn(async_test.topLevelFunction, VoidTodynamic());
  async_test.topLevelWithParameter = function(a) {
    return dart.async(function*(a) {
      return 7 + dart.notNull(a);
    }, core.int, a);
  };
  dart.fn(async_test.topLevelWithParameter, intToFutureOfint());
  async_test.topLevelWithParameterWrongType = function(a) {
    return dart.async(function*(a) {
      return 7 + dart.notNull(a);
    }, dart.dynamic, a);
  };
  dart.fn(async_test.topLevelWithParameterWrongType, intTodynamic());
  async_test.what = 'async getter';
  dart.copyProperties(async_test, {
    get topLevelGetter() {
      return dart.async(function*() {
        return dart.str`I want to be an ${async_test.what}`;
      }, core.String);
    }
  });
  const _x = Symbol('_x');
  async_test.A = class A extends core.Object {
    static staticMethod(param) {
      return dart.async(function*(param) {
        return dart.notNull(async_test.A.staticVar) + dart.notNull(param);
      }, dart.dynamic, param);
    }
    static get staticGetter() {
      return dart.async(function*() {
        return dart.notNull(async_test.A.staticVar) + 3;
      }, dart.dynamic);
    }
    new(x) {
      this[_x] = x;
    }
    ['+'](other) {
      return dart.async((function*(other) {
        return new async_test.A(dart.notNull(this[_x]) + dart.notNull(other[_x]));
      }).bind(this), dart.dynamic, other);
    }
    get value() {
      return this[_x];
    }
  };
  dart.setSignature(async_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(async_test.A, [core.int])}),
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [async_test.A])}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [core.int])}),
    names: ['staticMethod']
  });
  async_test.A.staticVar = 1;
  const _y = Symbol('_y');
  async_test.B = class B extends core.Object {
    _internal(y) {
      this[_y] = y;
    }
    new() {
      this[_y] = null;
    }
  };
  dart.defineNamedConstructor(async_test.B, '_internal');
  dart.setSignature(async_test.B, {
    constructors: () => ({
      _internal: dart.definiteFunctionType(async_test.B, [dart.dynamic]),
      new: dart.definiteFunctionType(async_test.B, [])
    })
  });
  async_test.main = function() {
    let asyncReturn = null;
    asyncReturn = async_test.topLevelFunction();
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    asyncReturn = async_test.topLevelWithParameter(4);
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result, 11), intTovoid()));
    asyncReturn = async_test.topLevelGetter;
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.stringEquals(result, 'I want to be an async getter'), StringTovoid()));
    asyncReturn = async_test.A.staticMethod(2);
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result, 3), intTovoid()));
    asyncReturn = async_test.A.staticGetter;
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result, 4), intTovoid()));
    let a = new async_test.A(13);
    let b = new async_test.A(9);
    asyncReturn = a['+'](b);
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result.value, 22), ATovoid()));
    let foo = 17;
    function bar(p1, p2) {
      return dart.async(function*(p1, p2) {
        let z = 8;
        return dart.dsend(dart.dsend(p2, '+', z), '+', foo);
      }, dart.dynamic, p1, p2);
    }
    dart.fn(bar, intAnddynamicTodynamic());
    asyncReturn = bar(1, 2);
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result, 27), intTovoid()));
    let moreNesting = dart.fn((shadowP1, p2, p3) => {
      let z = 3;
      function aa(shadowP1) {
        return dart.async(function*(shadowP1) {
          return foo + z + dart.notNull(p3) + dart.notNull(shadowP1);
        }, dart.dynamic, shadowP1);
      }
      dart.fn(aa, intTodynamic());
      return aa(6);
    }, intAndStringAndnumTodynamic());
    asyncReturn = moreNesting(1, "ignore", 2);
    expect$.Expect.isTrue(async.Future.is(asyncReturn));
    dart.dsend(asyncReturn, 'then', dart.fn(result => expect$.Expect.equals(result, 28), intTovoid()));
    let checkAsync = dart.fn(someFunc => {
      let toTest = dart.dcall(someFunc);
      expect$.Expect.isTrue(async.Future.is(toTest));
      dart.dsend(toTest, 'then', dart.fn(result => expect$.Expect.equals(result, 4), intTovoid()));
    }, dynamicTodynamic());
    dart.dcall(checkAsync, dart.fn(() => dart.async(function*() {
      return 4;
    }, core.int), VoidToFutureOfint()));
  };
  dart.fn(async_test.main, VoidTodynamic());
  // Exports:
  exports.async_test = async_test;
});
