dart_library.library('language/state_mangling4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__state_mangling4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const state_mangling4_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  state_mangling4_test.foo = function(env1) {
    if (env1 == null) return 0;
    let env0 = 0;
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(env1, 'length'))); i++) {
      env0 = dart.notNull(env0) + dart.notNull(core.int._check(dart.dindex(env1, i)));
    }
    env1 = state_mangling4_test.inscrutableId(new state_mangling4_test.A());
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(env1, 'length'))); i++) {
      env0 = dart.notNull(env0) + dart.notNull(core.int._check(dart.dindex(env1, i)));
    }
    return env0;
  };
  dart.fn(state_mangling4_test.foo, dynamicTodynamic());
  state_mangling4_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(state_mangling4_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(state_mangling4_test.inscrutable, intToint());
  state_mangling4_test.inscrutableId = function(x) {
    if (dart.equals(x, 0)) return state_mangling4_test.inscrutable(core.int._check(x));
    return 3 == state_mangling4_test.inscrutable(3) ? x : false;
  };
  dart.fn(state_mangling4_test.inscrutableId, dynamicTodynamic());
  state_mangling4_test.A = class A extends core.Object {
    new() {
      this.length = 3;
    }
    get(i) {
      return 1;
    }
  };
  dart.setSignature(state_mangling4_test.A, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  state_mangling4_test.main = function() {
    expect$.Expect.equals(9, state_mangling4_test.foo(JSArrayOfint().of([1, 2, 3])));
    if (dart.equals(state_mangling4_test.inscrutableId(0), 0)) {
      expect$.Expect.equals(6, state_mangling4_test.foo(new state_mangling4_test.A()));
    }
  };
  dart.fn(state_mangling4_test.main, VoidTodynamic());
  // Exports:
  exports.state_mangling4_test = state_mangling4_test;
});
