dart_library.library('language/truncdiv_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__truncdiv_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const truncdiv_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  truncdiv_test.main = function() {
    for (let i = -30; i < 30; i++) {
      expect$.Expect.equals(i[dartx['%']](9), truncdiv_test.foo(i, 9));
      if (i < 0) {
        expect$.Expect.equals((i / -i)[dartx.truncate](), truncdiv_test.foo2(i));
      } else if (i > 0) {
        expect$.Expect.equals((i / i)[dartx.truncate](), truncdiv_test.foo2(i));
      }
    }
    expect$.Expect.throws(dart.fn(() => truncdiv_test.foo(12, 0), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => truncdiv_test.foo2(0), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
  };
  dart.fn(truncdiv_test.main, VoidTodynamic());
  truncdiv_test.foo = function(i, x) {
    return dart.dsend(i, '%', x);
  };
  dart.fn(truncdiv_test.foo, dynamicAnddynamicTodynamic());
  truncdiv_test.foo2 = function(i) {
    let x = 0;
    if (dart.test(dart.dsend(i, '<', 0))) {
      x = core.int._check(dart.dsend(i, 'unary-'));
    } else {
      x = core.int._check(i);
    }
    return dart.dsend(i, '~/', x);
  };
  dart.fn(truncdiv_test.foo2, dynamicTodynamic());
  // Exports:
  exports.truncdiv_test = truncdiv_test;
});
