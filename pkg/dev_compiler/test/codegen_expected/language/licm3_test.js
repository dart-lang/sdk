dart_library.library('language/licm3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__licm3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const licm3_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  licm3_test.foo = function(o) {
    let r = 0;
    for (let i = 0; i < 3; i++) {
      r = dart.notNull(r) + dart.notNull(core.int._check(dart.dload(o, 'z')));
    }
    return r;
  };
  dart.fn(licm3_test.foo, dynamicTodynamic());
  licm3_test.A = class A extends core.Object {
    new() {
      this.z = 3;
    }
  };
  licm3_test.main = function() {
    let a = new licm3_test.A();
    for (let i = 0; i < 10000; i++)
      licm3_test.foo(a);
    expect$.Expect.equals(9, licm3_test.foo(a));
    expect$.Expect.throws(dart.fn(() => licm3_test.foo(42), VoidTovoid()));
    for (let i = 0; i < 10000; i++)
      licm3_test.foo(a);
    expect$.Expect.throws(dart.fn(() => licm3_test.foo(42), VoidTovoid()));
  };
  dart.fn(licm3_test.main, VoidTodynamic());
  // Exports:
  exports.licm3_test = licm3_test;
});
