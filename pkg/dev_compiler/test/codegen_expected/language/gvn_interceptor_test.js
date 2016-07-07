dart_library.library('language/gvn_interceptor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__gvn_interceptor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const gvn_interceptor_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  gvn_interceptor_test.foo = function(a, index) {
    if (dart.test(dart.dsend(dart.dload(a, 'length'), '<', index))) {
      for (let i = core.int._check(dart.dload(a, 'length')); dart.notNull(i) <= dart.notNull(core.num._check(index)); i = dart.notNull(i) + 1)
        dart.dsend(a, 'add', i);
    }
    return dart.dindex(a, dart.dsend(dart.dload(a, 'length'), '-', 1));
  };
  dart.fn(gvn_interceptor_test.foo, dynamicAnddynamicTodynamic());
  gvn_interceptor_test.main = function() {
    expect$.Expect.equals(3, gvn_interceptor_test.foo(JSArrayOfint().of([0]), 3));
  };
  dart.fn(gvn_interceptor_test.main, VoidTovoid());
  // Exports:
  exports.gvn_interceptor_test = gvn_interceptor_test;
});
