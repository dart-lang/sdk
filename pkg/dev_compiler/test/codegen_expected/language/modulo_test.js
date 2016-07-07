dart_library.library('language/modulo_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__modulo_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const modulo_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  modulo_test.main = function() {
    modulo_test.noDom(1);
    modulo_test.noDom(-1);
    for (let i = -30; i < 30; i++) {
      expect$.Expect.equals(i[dartx['%']](256), modulo_test.foo(i));
      expect$.Expect.equals(i[dartx['%']](-256), modulo_test.boo(i));
      expect$.Expect.throws(dart.fn(() => modulo_test.hoo(i), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
      expect$.Expect.equals((i / 254)[dartx.truncate]() + i[dartx['%']](254), modulo_test.fooTwo(i));
      expect$.Expect.equals((i / -254)[dartx.truncate]() + i[dartx['%']](-254), modulo_test.booTwo(i));
      expect$.Expect.throws(dart.fn(() => modulo_test.hooTwo(i), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
      if (i > 0) {
        expect$.Expect.equals(i[dartx['%']](10), modulo_test.noDom(i));
      } else {
        expect$.Expect.equals((i / 10)[dartx.truncate](), modulo_test.noDom(i));
      }
      expect$.Expect.equals((i / 10)[dartx.truncate]() + i[dartx['%']](10) + i[dartx['%']](10), modulo_test.threeOp(i));
      expect$.Expect.equals((i / 10)[dartx.truncate]() + (i / 12)[dartx.truncate]() + i[dartx['%']](10) + i[dartx['%']](12), modulo_test.fourOp(i));
      if (i < 0) {
        expect$.Expect.equals(i[dartx['%']](-i), modulo_test.foo2(i));
        expect$.Expect.equals((i / -i)[dartx.truncate]() + i[dartx['%']](-i), modulo_test.fooTwo2(i));
      } else if (i > 0) {
        expect$.Expect.equals(i[dartx['%']](i), modulo_test.foo2(i));
        expect$.Expect.equals((i / i)[dartx.truncate]() + i[dartx['%']](i), modulo_test.fooTwo2(i));
      }
    }
    expect$.Expect.throws(dart.fn(() => modulo_test.foo2(0), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => modulo_test.fooTwo2(0), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
  };
  dart.fn(modulo_test.main, VoidTodynamic());
  modulo_test.foo = function(i) {
    return dart.dsend(i, '%', 256);
  };
  dart.fn(modulo_test.foo, dynamicTodynamic());
  modulo_test.boo = function(i) {
    return dart.dsend(i, '%', -256);
  };
  dart.fn(modulo_test.boo, dynamicTodynamic());
  modulo_test.hoo = function(i) {
    return dart.dsend(i, '%', 0);
  };
  dart.fn(modulo_test.hoo, dynamicTodynamic());
  modulo_test.fooTwo = function(i) {
    return dart.dsend(dart.dsend(i, '~/', 254), '+', dart.dsend(i, '%', 254));
  };
  dart.fn(modulo_test.fooTwo, dynamicTodynamic());
  modulo_test.booTwo = function(i) {
    return dart.dsend(dart.dsend(i, '~/', -254), '+', dart.dsend(i, '%', -254));
  };
  dart.fn(modulo_test.booTwo, dynamicTodynamic());
  modulo_test.hooTwo = function(i) {
    return dart.dsend(dart.dsend(i, '~/', 0), '+', dart.dsend(i, '%', 0));
  };
  dart.fn(modulo_test.hooTwo, dynamicTodynamic());
  modulo_test.noDom = function(a) {
    let x = null;
    if (dart.test(dart.dsend(a, '>', 0))) {
      x = dart.dsend(a, '%', 10);
    } else {
      x = dart.dsend(a, '~/', 10);
    }
    return x;
  };
  dart.fn(modulo_test.noDom, dynamicTodynamic());
  modulo_test.threeOp = function(a) {
    let x = dart.dsend(a, '~/', 10);
    let y = dart.dsend(a, '%', 10);
    let z = dart.dsend(a, '%', 10);
    return dart.dsend(dart.dsend(x, '+', y), '+', z);
  };
  dart.fn(modulo_test.threeOp, dynamicTodynamic());
  modulo_test.fourOp = function(a) {
    let x0 = dart.dsend(a, '~/', 10);
    let x1 = dart.dsend(a, '~/', 12);
    let y0 = dart.dsend(a, '%', 10);
    let y1 = dart.dsend(a, '%', 12);
    return dart.dsend(dart.dsend(dart.dsend(x0, '+', x1), '+', y0), '+', y1);
  };
  dart.fn(modulo_test.fourOp, dynamicTodynamic());
  modulo_test.foo2 = function(i) {
    let x = 0;
    if (dart.test(dart.dsend(i, '<', 0))) {
      x = core.int._check(dart.dsend(i, 'unary-'));
    } else {
      x = core.int._check(i);
    }
    return dart.dsend(i, '%', x);
  };
  dart.fn(modulo_test.foo2, dynamicTodynamic());
  modulo_test.fooTwo2 = function(i) {
    let x = 0;
    if (dart.test(dart.dsend(i, '<', 0))) {
      x = core.int._check(dart.dsend(i, 'unary-'));
    } else {
      x = core.int._check(i);
    }
    return dart.dsend(dart.dsend(i, '~/', x), '+', dart.dsend(i, '%', x));
  };
  dart.fn(modulo_test.fooTwo2, dynamicTodynamic());
  // Exports:
  exports.modulo_test = modulo_test;
});
