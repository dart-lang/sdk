dart_library.library('language/const_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_syntax_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_syntax_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  const_syntax_test_none_multi.main = function() {
    let f0 = 42;
    let f2 = 87;
    expect$.Expect.equals(42, f0);
    expect$.Expect.equals(87, f2);
    expect$.Expect.equals(42, const_syntax_test_none_multi.F0);
    expect$.Expect.equals(87, const_syntax_test_none_multi.F2);
    expect$.Expect.isTrue(const_syntax_test_none_multi.Point.is(const_syntax_test_none_multi.P0));
    expect$.Expect.isTrue(typeof const_syntax_test_none_multi.A0 == 'number');
    expect$.Expect.isTrue(typeof const_syntax_test_none_multi.A1 == 'number');
    expect$.Expect.isTrue(const_syntax_test_none_multi.C1.is(const_syntax_test_none_multi.C0.X));
    expect$.Expect.equals("Hello 42", const_syntax_test_none_multi.B2);
    let cf1 = core.identical(const$ || (const$ = dart.const(new const_syntax_test_none_multi.Point(1, 2))), const$0 || (const$0 = dart.const(new const_syntax_test_none_multi.Point(1, 2))));
    let f5 = const_syntax_test_none_multi.B5;
  };
  dart.fn(const_syntax_test_none_multi.main, VoidTodynamic());
  const_syntax_test_none_multi.F0 = 42;
  const_syntax_test_none_multi.F2 = 87;
  const_syntax_test_none_multi.Point = class Point extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
    ['+'](other) {
      return this.x;
    }
  };
  dart.setSignature(const_syntax_test_none_multi.Point, {
    constructors: () => ({new: dart.definiteFunctionType(const_syntax_test_none_multi.Point, [dart.dynamic, dart.dynamic])}),
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [core.int])})
  });
  const_syntax_test_none_multi.P0 = dart.const(new const_syntax_test_none_multi.Point(0, 0));
  const_syntax_test_none_multi.A0 = 42;
  const_syntax_test_none_multi.A1 = const_syntax_test_none_multi.A0 + 1;
  const_syntax_test_none_multi.C0 = class C0 extends core.Object {};
  dart.defineLazy(const_syntax_test_none_multi.C0, {
    get X() {
      return dart.const(new const_syntax_test_none_multi.C1());
    }
  });
  const_syntax_test_none_multi.C1 = class C1 extends core.Object {
    new() {
      this.x = null;
    }
  };
  dart.setSignature(const_syntax_test_none_multi.C1, {
    constructors: () => ({new: dart.definiteFunctionType(const_syntax_test_none_multi.C1, [])})
  });
  const_syntax_test_none_multi.B0 = 42;
  const_syntax_test_none_multi.B1 = "Hello";
  const_syntax_test_none_multi.B2 = dart.str`${const_syntax_test_none_multi.B1} ${const_syntax_test_none_multi.B0}`;
  const_syntax_test_none_multi.B5 = core.identical(1, dart.const(new const_syntax_test_none_multi.Point(1, 2)));
  // Exports:
  exports.const_syntax_test_none_multi = const_syntax_test_none_multi;
});
