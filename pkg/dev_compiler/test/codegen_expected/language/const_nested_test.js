dart_library.library('language/const_nested_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_nested_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_nested_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_nested_test.N = 8;
  const_nested_test.ConstFoo = class ConstFoo extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(const_nested_test.ConstFoo, {
    constructors: () => ({new: dart.definiteFunctionType(const_nested_test.ConstFoo, [dart.dynamic])})
  });
  let const$;
  let const$0;
  let const$1;
  const_nested_test.getClosure = function() {
    let MIN = 2 - 1;
    let MAX = const_nested_test.N * 2;
    let MASK = (1)[dartx['<<']](MAX - MIN + 1) - 1;
    function foo() {
      expect$.Expect.equals(1, MIN);
      expect$.Expect.equals(16, MAX);
      expect$.Expect.equals(65535, MASK);
      let s = dart.str`MIN = ${MIN}  MAX = ${MAX}  MASK = ${MASK}`;
      expect$.Expect.isTrue(core.identical(s, dart.str`MIN = ${MIN}  MAX = ${MAX}  MASK = ${MASK}`));
      expect$.Expect.equals("MIN = 1  MAX = 16  MASK = 65535", s);
      let cf1 = const$ || (const$ = dart.const(new const_nested_test.ConstFoo(MASK)));
      let cf2 = const$0 || (const$0 = dart.const(new const_nested_test.ConstFoo(s)));
      let cf3 = const$1 || (const$1 = dart.const(new const_nested_test.ConstFoo(dart.str`MIN = ${MIN}  MAX = ${MAX}  MASK = ${MASK}`)));
      expect$.Expect.isTrue(core.identical(cf2, cf3));
      expect$.Expect.isFalse(core.identical(cf2, cf1));
    }
    dart.fn(foo, VoidTovoid());
    return foo;
  };
  dart.fn(const_nested_test.getClosure, VoidTodynamic());
  const_nested_test.main = function() {
    let f = const_nested_test.getClosure();
    dart.dcall(f);
  };
  dart.fn(const_nested_test.main, VoidTodynamic());
  // Exports:
  exports.const_nested_test = const_nested_test;
});
