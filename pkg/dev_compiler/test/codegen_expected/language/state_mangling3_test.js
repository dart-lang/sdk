dart_library.library('language/state_mangling3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__state_mangling3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const state_mangling3_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  state_mangling3_test.foo = function(state0) {
    if (state0 == null) return 0;
    let sum = 0;
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(state0, 'length'))); i++) {
      sum = dart.notNull(sum) + dart.notNull(core.int._check(dart.dindex(state0, i)));
    }
    state0 = state_mangling3_test.inscrutableId(state0);
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(state0, 'length'))); i++) {
      sum = dart.notNull(sum) + dart.notNull(core.int._check(dart.dindex(state0, i)));
    }
    return sum;
  };
  dart.fn(state_mangling3_test.foo, dynamicTodynamic());
  state_mangling3_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(state_mangling3_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(state_mangling3_test.inscrutable, intToint());
  state_mangling3_test.inscrutableId = function(x) {
    if (dart.equals(x, 0)) return state_mangling3_test.inscrutable(core.int._check(x));
    return 3 == state_mangling3_test.inscrutable(3) ? x : false;
  };
  dart.fn(state_mangling3_test.inscrutableId, dynamicTodynamic());
  state_mangling3_test.A = class A extends core.Object {
    new() {
      this.length = 3;
    }
    get(i) {
      return 1;
    }
  };
  dart.setSignature(state_mangling3_test.A, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  state_mangling3_test.main = function() {
    expect$.Expect.equals(12, state_mangling3_test.foo(JSArrayOfint().of([1, 2, 3])));
    if (dart.equals(state_mangling3_test.inscrutableId(0), 0)) {
      expect$.Expect.equals(6, state_mangling3_test.foo(new state_mangling3_test.A()));
    }
  };
  dart.fn(state_mangling3_test.main, VoidTodynamic());
  // Exports:
  exports.state_mangling3_test = state_mangling3_test;
});
