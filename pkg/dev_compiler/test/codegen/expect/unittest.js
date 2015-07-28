dart_library.library('unittest', null, /* Imports */[
  "dart_runtime/dart",
  'dom/dom',
  'dart/core',
  'dart/async'
], /* Lazy imports */[
], function(exports, dart, dom, core, async) {
  'use strict';
  let dartx = dart.dartx;
  function group(name, body) {
    return dart.dsend(dart.as(dom.window, dart.dynamic), 'suite', name, body);
  }
  dart.fn(group, dart.void, [core.String, dart.functionType(dart.void, [])]);
  function test(name, body, opts) {
    let skip = opts && 'skip' in opts ? opts.skip : null;
    if (skip != null) {
      core.print(`SKIP ${name}: ${skip}`);
      return;
    }
    dart.dsend(dart.as(dom.window, dart.dynamic), 'test', name, dart.fn(done => {
      function _finishTest(f) {
        if (dart.is(f, async.Future)) {
          dart.dsend(f, 'then', _finishTest);
        } else {
          dart.dcall(done);
        }
      }
      dart.fn(_finishTest);
      _finishTest(body());
    }));
  }
  dart.fn(test, dart.void, [core.String, dart.functionType(dart.dynamic, [])], {skip: core.String});
  function expect(actual, matcher) {
    if (!dart.is(matcher, Matcher))
      matcher = equals(matcher);
    if (!dart.notNull(dart.as(dart.dcall(matcher, actual), core.bool))) {
      dart.throw(`Expect failed to match ${actual} with ${matcher}`);
    }
  }
  dart.fn(expect, dart.void, [core.Object, dart.dynamic]);
  function fail(message) {
    dart.throw('TestFailure: ' + dart.notNull(message));
  }
  dart.fn(fail, dart.void, [core.String]);
  function equals(expected) {
    return dart.fn(actual => {
      if (dart.is(expected, core.List) && dart.is(actual, core.List)) {
        let len = expected[dartx.length];
        if (!dart.equals(len, dart.dload(actual, 'length')))
          return false;
        for (let i = 0; dart.notNull(i) < dart.notNull(len); i = dart.notNull(i) + 1) {
          if (!dart.notNull(dart.as(dart.dcall(equals(expected[dartx.get](i)), dart.dindex(actual, i)), core.bool)))
            return false;
        }
        return true;
      } else {
        return dart.equals(expected, actual);
      }
    });
  }
  dart.fn(equals, () => dart.definiteFunctionType(Matcher, [core.Object]));
  function same(expected) {
    return dart.fn(actual => core.identical(expected, actual), core.bool, [dart.dynamic]);
  }
  dart.fn(same, () => dart.definiteFunctionType(Matcher, [core.Object]));
  function isNot(matcher) {
    if (!dart.is(matcher, Matcher))
      matcher = equals(matcher);
    return dart.fn(actual => !dart.notNull(dart.as(dart.dcall(matcher, actual), core.bool)), core.bool, [dart.dynamic]);
  }
  dart.fn(isNot, () => dart.definiteFunctionType(Matcher, [dart.dynamic]));
  function isTrue(actual) {
    return dart.equals(actual, true);
  }
  dart.fn(isTrue, core.bool, [dart.dynamic]);
  function isNull(actual) {
    return actual == null;
  }
  dart.fn(isNull, core.bool, [dart.dynamic]);
  dart.defineLazyProperties(exports, {
    get isNotNull() {
      return isNot(isNull);
    }
  });
  function isRangeError(actual) {
    return dart.is(actual, core.RangeError);
  }
  dart.fn(isRangeError, core.bool, [dart.dynamic]);
  function isNoSuchMethodError(actual) {
    return dart.is(actual, core.NoSuchMethodError);
  }
  dart.fn(isNoSuchMethodError, core.bool, [dart.dynamic]);
  function lessThan(expected) {
    return dart.fn(actual => dart.dsend(actual, '<', expected));
  }
  dart.fn(lessThan, () => dart.definiteFunctionType(Matcher, [dart.dynamic]));
  function greaterThan(expected) {
    return dart.fn(actual => dart.dsend(actual, '>', expected));
  }
  dart.fn(greaterThan, () => dart.definiteFunctionType(Matcher, [dart.dynamic]));
  function throwsA(matcher) {
    if (!dart.is(matcher, Matcher))
      matcher = equals(matcher);
    return dart.fn(actual => {
      try {
        dart.dcall(actual);
        return false;
      } catch (e) {
        return dart.dcall(matcher, e);
      }

    });
  }
  dart.fn(throwsA, () => dart.definiteFunctionType(Matcher, [dart.dynamic]));
  dart.defineLazyProperties(exports, {
    get throws() {
      return throwsA(dart.fn(a => true, core.bool, [dart.dynamic]));
    }
  });
  let Matcher = dart.typedef('Matcher', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  // Exports:
  exports.group = group;
  exports.test = test;
  exports.expect = expect;
  exports.fail = fail;
  exports.equals = equals;
  exports.same = same;
  exports.isNot = isNot;
  exports.isTrue = isTrue;
  exports.isNull = isNull;
  exports.isRangeError = isRangeError;
  exports.isNoSuchMethodError = isNoSuchMethodError;
  exports.lessThan = lessThan;
  exports.greaterThan = greaterThan;
  exports.throwsA = throwsA;
  exports.Matcher = Matcher;
});
