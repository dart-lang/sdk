dart_library.library('language/nested_if_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__nested_if_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const nested_if_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  nested_if_test.foo = function(x, a) {
    for (let i = 0; i < 10; i++) {
      if (dart.test(x)) {
        if (!dart.test(x)) a = [];
        dart.dsend(a, 'add', 3);
      }
    }
    return a;
  };
  dart.fn(nested_if_test.foo, dynamicAnddynamicTodynamic());
  nested_if_test.main = function() {
    let a = nested_if_test.foo(true, []);
    expect$.Expect.equals(10, dart.dload(a, 'length'));
    expect$.Expect.equals(3, dart.dindex(a, 0));
  };
  dart.fn(nested_if_test.main, VoidTodynamic());
  // Exports:
  exports.nested_if_test = nested_if_test;
});
