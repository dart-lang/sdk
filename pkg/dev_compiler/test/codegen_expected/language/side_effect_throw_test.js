dart_library.library('language/side_effect_throw_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__side_effect_throw_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const side_effect_throw_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  side_effect_throw_test.B = class B extends core.Object {
    ['<<'](other) {
      side_effect_throw_test.B.x = other;
      return 33;
    }
  };
  dart.setSignature(side_effect_throw_test.B, {
    methods: () => ({'<<': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  side_effect_throw_test.B.x = null;
  const _m = Symbol('_m');
  side_effect_throw_test.A = class A extends core.Object {
    get [_m]() {
      return new side_effect_throw_test.B();
    }
    opshl(n) {
      return dart.dsend(dart.dsend(this[_m], '<<', 499), '|', 2 - dart.notNull(core.num._check(n)));
    }
  };
  dart.setSignature(side_effect_throw_test.A, {
    methods: () => ({opshl: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  side_effect_throw_test.main = function() {
    let a = new side_effect_throw_test.A();
    expect$.Expect.throws(dart.fn(() => a.opshl("string"), VoidTovoid()));
    expect$.Expect.equals(499, side_effect_throw_test.B.x);
  };
  dart.fn(side_effect_throw_test.main, VoidTodynamic());
  // Exports:
  exports.side_effect_throw_test = side_effect_throw_test;
});
