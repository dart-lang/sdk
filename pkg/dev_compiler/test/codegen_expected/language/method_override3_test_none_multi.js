dart_library.library('language/method_override3_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_override3_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_override3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  method_override3_test_none_multi.A = class A extends core.Object {
    foo(required1, opts) {
      let named1 = opts && 'named1' in opts ? opts.named1 : 499;
      return dart.dsend(dart.dsend(required1, '+', dart.dsend(named1, '*', 3)), 'unary-');
    }
    bar(required1, required2, opts) {
      let named1 = opts && 'named1' in opts ? opts.named1 : 13;
      let named2 = opts && 'named2' in opts ? opts.named2 : 17;
      return dart.dsend(dart.dsend(dart.dsend(dart.dsend(required1, '+', dart.dsend(required2, '*', 3)), '+', dart.dsend(named1, '*', 5)), '+', dart.dsend(named2, '*', 7)), 'unary-');
    }
    gee(opts) {
      let named1 = opts && 'named1' in opts ? opts.named1 : 31;
      return dart.dsend(named1, 'unary-');
    }
  };
  dart.setSignature(method_override3_test_none_multi.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {named1: dart.dynamic}),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic], {named1: dart.dynamic, named2: dart.dynamic}),
      gee: dart.definiteFunctionType(dart.dynamic, [], {named1: dart.dynamic})
    })
  });
  method_override3_test_none_multi.B = class B extends method_override3_test_none_multi.A {
    foo(required1, opts) {
      let named1 = opts && 'named1' in opts ? opts.named1 : 499;
      return required1;
    }
    bar(required1, required2, opts) {
      let named1 = opts && 'named1' in opts ? opts.named1 : 13;
      let named2 = opts && 'named2' in opts ? opts.named2 : 17;
      return dart.dsend(dart.dsend(required1, '+', dart.dsend(required2, '*', 3)), '+', dart.dsend(named1, '*', 5));
    }
    gee(opts) {
      let named2 = opts && 'named2' in opts ? opts.named2 : 11;
      let named1 = opts && 'named1' in opts ? opts.named1 : 31;
      return dart.dsend(named2, '*', 99);
    }
  };
  dart.setSignature(method_override3_test_none_multi.B, {
    methods: () => ({gee: dart.definiteFunctionType(dart.dynamic, [], {named2: dart.dynamic, named1: dart.dynamic})})
  });
  method_override3_test_none_multi.main = function() {
    let b = new method_override3_test_none_multi.B();
    expect$.Expect.equals(499, b.foo(499));
    expect$.Expect.equals(1 + 3 * 3 + 5 * 5, b.bar(1, 3, {named1: 5}));
    expect$.Expect.equals(1 + 3 * 3 + 13 * 5, b.bar(1, 3));
    expect$.Expect.equals(3 * 99, b.gee({named2: 3}));
    expect$.Expect.equals(11 * 99, b.gee());
  };
  dart.fn(method_override3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.method_override3_test_none_multi = method_override3_test_none_multi;
});
