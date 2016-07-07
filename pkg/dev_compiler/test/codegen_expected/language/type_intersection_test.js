dart_library.library('language/type_intersection_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_intersection_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_intersection_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_intersection_test.A = class A extends core.Object {
    foo(a, b) {
      return dart.equals(a, b);
    }
    bar(a, b) {
      return dart.equals(b, a);
    }
  };
  dart.setSignature(type_intersection_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, core.Comparable]),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, core.Comparable])
    })
  });
  type_intersection_test.main = function() {
    expect$.Expect.isFalse(new type_intersection_test.A().foo(1, 'foo'));
    expect$.Expect.isTrue(new type_intersection_test.A().foo(1, 1));
    expect$.Expect.isFalse(new type_intersection_test.A().bar(1, 'foo'));
    expect$.Expect.isTrue(new type_intersection_test.A().bar(1, 1));
  };
  dart.fn(type_intersection_test.main, VoidTodynamic());
  // Exports:
  exports.type_intersection_test = type_intersection_test;
});
