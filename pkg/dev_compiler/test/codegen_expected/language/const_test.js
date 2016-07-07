dart_library.library('language/const_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_test.AConst = class AConst extends core.Object {
    new() {
      this.b_ = 3;
    }
  };
  dart.setSignature(const_test.AConst, {
    constructors: () => ({new: dart.definiteFunctionType(const_test.AConst, [])})
  });
  const_test.BConst = class BConst extends core.Object {
    new() {
    }
    set foo(value) {}
    get foo() {
      return 5;
    }
    get(ix) {
      return ix;
    }
    set(ix, value) {
      return value;
    }
  };
  dart.setSignature(const_test.BConst, {
    constructors: () => ({new: dart.definiteFunctionType(const_test.BConst, [])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
    })
  });
  let const$;
  let const$0;
  let const$1;
  const_test.testMain = function() {
    let o = const$ || (const$ = dart.const(new const_test.AConst()));
    expect$.Expect.equals(3, o.b_);
    let o$ = const$0 || (const$0 = dart.const(new const_test.BConst()));
    let x = o$.foo;
    o$.foo = dart.dsend(x, '+', 1);
    expect$.Expect.equals(5, x);
    let o$0 = const$1 || (const$1 = dart.const(new const_test.BConst())), i = 5;
    let y = o$0.get(i);
    o$0.set(i, dart.dsend(y, '+', 1));
    expect$.Expect.equals(5, y);
  };
  dart.fn(const_test.testMain, VoidTodynamic());
  const_test.main = function() {
    for (let i = 0; i < 20; i++) {
      const_test.testMain();
    }
  };
  dart.fn(const_test.main, VoidTodynamic());
  // Exports:
  exports.const_test = const_test;
});
