dart_library.library('language/final_syntax_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__final_syntax_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const final_syntax_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_syntax_test_01_multi.main = function() {
    let f0 = 42;
    let f1 = null;
    let f2 = 87;
    expect$.Expect.equals(42, f0);
    expect$.Expect.equals(87, f2);
    expect$.Expect.equals(42, final_syntax_test_01_multi.F0);
    expect$.Expect.equals(87, final_syntax_test_01_multi.F2);
    expect$.Expect.isTrue(final_syntax_test_01_multi.Point.is(final_syntax_test_01_multi.P0));
    expect$.Expect.isTrue(typeof final_syntax_test_01_multi.P1 == 'number');
    expect$.Expect.isTrue(final_syntax_test_01_multi.Point.is(final_syntax_test_01_multi.P2));
    expect$.Expect.isTrue(typeof final_syntax_test_01_multi.P3 == 'number');
    expect$.Expect.isTrue(typeof final_syntax_test_01_multi.A0 == 'number');
    expect$.Expect.isTrue(typeof final_syntax_test_01_multi.A1 == 'number');
    expect$.Expect.isTrue(final_syntax_test_01_multi.C1.is(final_syntax_test_01_multi.C0.X));
    expect$.Expect.equals("Hello 42", final_syntax_test_01_multi.B2);
  };
  dart.fn(final_syntax_test_01_multi.main, VoidTodynamic());
  final_syntax_test_01_multi.F0 = 42;
  final_syntax_test_01_multi.F2 = 87;
  final_syntax_test_01_multi.Point = class Point extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
    ['+'](other) {
      return this.x;
    }
  };
  dart.setSignature(final_syntax_test_01_multi.Point, {
    constructors: () => ({new: dart.definiteFunctionType(final_syntax_test_01_multi.Point, [dart.dynamic, dart.dynamic])}),
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [core.int])})
  });
  final_syntax_test_01_multi.P0 = dart.const(new final_syntax_test_01_multi.Point(0, 0));
  dart.defineLazy(final_syntax_test_01_multi, {
    get P1() {
      return dart.const(new final_syntax_test_01_multi.Point(0, 0))['+'](1);
    }
  });
  dart.defineLazy(final_syntax_test_01_multi, {
    get P2() {
      return new final_syntax_test_01_multi.Point(0, 0);
    }
  });
  dart.defineLazy(final_syntax_test_01_multi, {
    get P3() {
      return new final_syntax_test_01_multi.Point(0, 0)['+'](1);
    }
  });
  final_syntax_test_01_multi.A0 = 42;
  dart.defineLazy(final_syntax_test_01_multi, {
    get A1() {
      return dart.notNull(final_syntax_test_01_multi.A0) + 1;
    }
  });
  final_syntax_test_01_multi.C0 = class C0 extends core.Object {};
  dart.defineLazy(final_syntax_test_01_multi.C0, {
    get X() {
      return dart.const(new final_syntax_test_01_multi.C1());
    }
  });
  final_syntax_test_01_multi.C1 = class C1 extends core.Object {
    new() {
      this.x = null;
    }
  };
  dart.setSignature(final_syntax_test_01_multi.C1, {
    constructors: () => ({new: dart.definiteFunctionType(final_syntax_test_01_multi.C1, [])})
  });
  final_syntax_test_01_multi.B0 = 42;
  final_syntax_test_01_multi.B1 = "Hello";
  dart.defineLazy(final_syntax_test_01_multi, {
    get B2() {
      return dart.str`${final_syntax_test_01_multi.B1} ${final_syntax_test_01_multi.B0}`;
    }
  });
  // Exports:
  exports.final_syntax_test_01_multi = final_syntax_test_01_multi;
});
