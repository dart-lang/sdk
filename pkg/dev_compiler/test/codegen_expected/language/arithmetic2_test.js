dart_library.library('language/arithmetic2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__arithmetic2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const arithmetic2_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTonum = () => (dynamicTonum = dart.constFn(dart.definiteFunctionType(core.num, [dart.dynamic])))();
  let dynamicTodouble = () => (dynamicTodouble = dart.constFn(dart.definiteFunctionType(core.double, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  arithmetic2_test.A = class A extends core.Object {
    static foo() {
      return 499;
    }
  };
  dart.setSignature(arithmetic2_test.A, {
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  arithmetic2_test.throwsNoSuchMethod = function(f) {
    try {
      dart.dcall(f);
      return false;
    } catch (e) {
      if (core.NoSuchMethodError.is(e)) {
        return true;
      } else
        throw e;
    }

    return false;
  };
  dart.fn(arithmetic2_test.throwsNoSuchMethod, dynamicTobool());
  arithmetic2_test.throwsBecauseOfBadArgument = function(f) {
    try {
      dart.dcall(f);
      return false;
    } catch (e$) {
      if (core.NoSuchMethodError.is(e$)) {
        let e = e$;
        return true;
      } else if (core.ArgumentError.is(e$)) {
        let e = e$;
        return true;
      } else if (core.TypeError.is(e$)) {
        let e = e$;
        return true;
      } else
        throw e$;
    }

    return false;
  };
  dart.fn(arithmetic2_test.throwsBecauseOfBadArgument, dynamicTobool());
  arithmetic2_test.numberOpBadSecondArgument = function(f) {
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, true), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, new arithmetic2_test.A()), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, "foo"), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, "5"), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, dart.fn(() => 499, VoidToint())), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, null), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, false), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, []), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, dart.map()), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsBecauseOfBadArgument(dart.fn(() => dart.dcall(f, arithmetic2_test.A.foo), VoidTodynamic())));
  };
  dart.fn(arithmetic2_test.numberOpBadSecondArgument, dynamicTodynamic());
  arithmetic2_test.badOperations = function(b) {
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '-', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '*', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '~/', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '/', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '%', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '+', 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dindex(b, 3), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, '~'), VoidTodynamic())));
    expect$.Expect.isTrue(arithmetic2_test.throwsNoSuchMethod(dart.fn(() => dart.dsend(b, 'unary-'), VoidTodynamic())));
  };
  dart.fn(arithmetic2_test.badOperations, dynamicTodynamic());
  arithmetic2_test.main = function() {
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => 3 + dart.notNull(core.num._check(x)), dynamicTonum()));
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => 3 - dart.notNull(core.num._check(x)), dynamicTonum()));
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => 3 * dart.notNull(core.num._check(x)), dynamicTonum()));
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => 3 / dart.notNull(core.num._check(x)), dynamicTodouble()));
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => (3 / dart.notNull(core.num._check(x)))[dartx.truncate](), dynamicToint()));
    arithmetic2_test.numberOpBadSecondArgument(dart.fn(x => (3)[dartx['%']](core.num._check(x)), dynamicTonum()));
    arithmetic2_test.badOperations(true);
    arithmetic2_test.badOperations(false);
    arithmetic2_test.badOperations(dart.fn(() => 499, VoidToint()));
    arithmetic2_test.badOperations(arithmetic2_test.A.foo);
  };
  dart.fn(arithmetic2_test.main, VoidTodynamic());
  // Exports:
  exports.arithmetic2_test = arithmetic2_test;
});
