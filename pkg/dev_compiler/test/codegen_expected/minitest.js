define(['dart_sdk', 'expect'], function(dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const minitest = Object.create(null);
  let JSArrayOf_Group = () => (JSArrayOf_Group = dart.constFn(_interceptors.JSArray$(minitest._Group)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let ObjectTobool = () => (ObjectTobool = dart.constFn(dart.functionType(core.bool, [core.Object])))();
  let ObjectTovoid = () => (ObjectTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Object])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let StringAndFnTovoid = () => (StringAndFnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, VoidTodynamic()])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [VoidTodynamic()])))();
  let ObjectAndObject__Tovoid = () => (ObjectAndObject__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Object, core.Object], {reason: core.String})))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let ObjectToObject = () => (ObjectToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.Object])))();
  let Fn__ToObject = () => (Fn__ToObject = dart.constFn(dart.definiteFunctionType(core.Object, [ObjectTobool()], [core.String])))();
  let numAndnumToObject = () => (numAndnumToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.num, core.num])))();
  let numToObject = () => (numToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.num])))();
  minitest._Action = dart.typedef('_Action', () => dart.functionType(dart.void, []));
  minitest._ExpectationFunction = dart.typedef('_ExpectationFunction', () => dart.functionType(dart.void, [core.Object]));
  dart.defineLazy(minitest, {
    get _groups() {
      return JSArrayOf_Group().of([new minitest._Group()]);
    }
  });
  dart.defineLazy(minitest, {
    get isFalse() {
      return new minitest._Expectation(expect$.Expect.isFalse);
    }
  });
  dart.defineLazy(minitest, {
    get isNotNull() {
      return new minitest._Expectation(expect$.Expect.isNotNull);
    }
  });
  dart.defineLazy(minitest, {
    get isNull() {
      return new minitest._Expectation(expect$.Expect.isNull);
    }
  });
  dart.defineLazy(minitest, {
    get isTrue() {
      return new minitest._Expectation(expect$.Expect.isTrue);
    }
  });
  dart.defineLazy(minitest, {
    get returnsNormally() {
      return new minitest._Expectation(dart.fn(actual => {
        try {
          minitest._Action.as(actual)();
        } catch (error) {
          expect$.Expect.fail(dart.str`Expected function to return normally, but threw:\n${error}`);
        }

      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throws() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual));
      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throwsArgumentError() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual), dart.fn(error => core.ArgumentError.is(error), dynamicTobool()));
      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throwsNoSuchMethodError() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual), dart.fn(error => core.NoSuchMethodError.is(error), dynamicTobool()));
      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throwsRangeError() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual), dart.fn(error => core.RangeError.is(error), dynamicTobool()));
      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throwsStateError() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual), dart.fn(error => core.StateError.is(error), dynamicTobool()));
      }, ObjectTovoid()));
    }
  });
  dart.defineLazy(minitest, {
    get throwsUnsupportedError() {
      return new minitest._Expectation(dart.fn(actual => {
        expect$.Expect.throws(minitest._Action.as(actual), dart.fn(error => core.UnsupportedError.is(error), dynamicTobool()));
      }, ObjectTovoid()));
    }
  });
  minitest.finishTests = function() {
    minitest._groups[dartx.clear]();
    minitest._groups[dartx.add](new minitest._Group());
  };
  dart.fn(minitest.finishTests, VoidTovoid());
  minitest.group = function(description, body) {
    minitest._groups[dartx.add](new minitest._Group());
    try {
      body();
    } finally {
      minitest._groups[dartx.removeLast]();
    }
  };
  dart.fn(minitest.group, StringAndFnTovoid());
  minitest.test = function(description, body) {
    for (let group of minitest._groups) {
      if (group.setUpFunction != null) group.setUpFunction();
    }
    try {
      body();
    } finally {
      for (let i = dart.notNull(minitest._groups[dartx.length]) - 1; i >= 0; i--) {
        let group = minitest._groups[dartx.get](i);
        if (group.tearDownFunction != null) group.tearDownFunction();
      }
    }
  };
  dart.fn(minitest.test, StringAndFnTovoid());
  minitest.setUp = function(body) {
    dart.assert(minitest._groups[dartx.last].setUpFunction == null);
    minitest._groups[dartx.last].setUpFunction = body;
  };
  dart.fn(minitest.setUp, FnTovoid());
  minitest.tearDown = function(body) {
    dart.assert(minitest._groups[dartx.last].tearDownFunction == null);
    minitest._groups[dartx.last].tearDownFunction = body;
  };
  dart.fn(minitest.tearDown, FnTovoid());
  minitest.expect = function(actual, expected, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    if (!minitest._Expectation.is(expected)) {
      expected = minitest.equals(expected);
    }
    let expectation = minitest._Expectation.as(expected);
    expectation.function(actual);
  };
  dart.fn(minitest.expect, ObjectAndObject__Tovoid());
  minitest.fail = function(message) {
    expect$.Expect.fail(message);
  };
  dart.fn(minitest.fail, StringTovoid());
  minitest.equals = function(value) {
    return new minitest._Expectation(dart.fn(actual => {
      expect$.Expect.deepEquals(value, actual);
    }, ObjectTovoid()));
  };
  dart.fn(minitest.equals, ObjectToObject());
  minitest.notEquals = function(value) {
    return new minitest._Expectation(dart.fn(actual => {
      expect$.Expect.notEquals(value, actual);
    }, ObjectTovoid()));
  };
  dart.fn(minitest.notEquals, ObjectToObject());
  minitest.unorderedEquals = function(value) {
    return new minitest._Expectation(dart.fn(actual => {
      expect$.Expect.setEquals(core.Iterable._check(value), core.Iterable._check(actual));
    }, ObjectTovoid()));
  };
  dart.fn(minitest.unorderedEquals, ObjectToObject());
  minitest.predicate = function(fn, description) {
    if (description === void 0) description = null;
    return new minitest._Expectation(dart.fn(actual => {
      expect$.Expect.isTrue(fn(actual));
    }, ObjectTovoid()));
  };
  dart.fn(minitest.predicate, Fn__ToObject());
  minitest.inInclusiveRange = function(min, max) {
    return new minitest._Expectation(dart.fn(actual => {
      let actualNum = core.num.as(actual);
      if (dart.notNull(actualNum) < dart.notNull(min) || dart.notNull(actualNum) > dart.notNull(max)) {
        minitest.fail(dart.str`Expected ${actualNum} to be in the inclusive range [${min}, ${max}].`);
      }
    }, ObjectTovoid()));
  };
  dart.fn(minitest.inInclusiveRange, numAndnumToObject());
  minitest.greaterThan = function(value) {
    return new minitest._Expectation(dart.fn(actual => {
      let actualNum = core.num.as(actual);
      if (dart.notNull(actualNum) <= dart.notNull(value)) {
        minitest.fail(dart.str`Expected ${actualNum} to be greater than ${value}.`);
      }
    }, ObjectTovoid()));
  };
  dart.fn(minitest.greaterThan, numToObject());
  minitest.same = function(value) {
    return new minitest._Expectation(dart.fn(actual => {
      expect$.Expect.identical(value, actual);
    }, ObjectTovoid()));
  };
  dart.fn(minitest.same, ObjectToObject());
  minitest._Group = class _Group extends core.Object {
    new() {
      this.setUpFunction = null;
      this.tearDownFunction = null;
    }
  };
  dart.setSignature(minitest._Group, {
    fields: () => ({
      setUpFunction: minitest._Action,
      tearDownFunction: minitest._Action
    })
  });
  minitest._Expectation = class _Expectation extends core.Object {
    new(func) {
      this.function = func;
    }
  };
  dart.setSignature(minitest._Expectation, {
    constructors: () => ({new: dart.definiteFunctionType(minitest._Expectation, [minitest._ExpectationFunction])}),
    fields: () => ({function: minitest._ExpectationFunction})
  });
  // Exports:
  return {
    minitest: minitest
  };
});
