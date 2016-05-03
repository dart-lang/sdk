dart_library.library('unittest', null, /* Imports */[
  'dart_sdk',
  'matcher'
], function(exports, dart_sdk, matcher) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const js = dart_sdk.js;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__util = matcher.src__util;
  const src__interfaces = matcher.src__interfaces;
  const src__description = matcher.src__description;
  const src__numeric_matchers = matcher.src__numeric_matchers;
  const src__error_matchers = matcher.src__error_matchers;
  const src__core_matchers = matcher.src__core_matchers;
  const src__iterable_matchers = matcher.src__iterable_matchers;
  const src__string_matchers = matcher.src__string_matchers;
  const src__operator_matchers = matcher.src__operator_matchers;
  const src__map_matchers = matcher.src__map_matchers;
  const unittest = Object.create(null);
  dart.defineLazy(unittest, {
    get _wrapAsync() {
      return dart.fn((f, id) => {
        if (id === void 0) id = null;
        return f;
      }, core.Function, [core.Function], [dart.dynamic]);
    },
    set _wrapAsync(_) {}
  });
  const _matcher = Symbol('_matcher');
  unittest.Throws = class Throws extends src__interfaces.Matcher {
    Throws(matcher) {
      if (matcher === void 0) matcher = null;
      this[_matcher] = matcher;
      super.Matcher();
    }
    matches(item, matchState) {
      if (!dart.is(item, core.Function) && !dart.is(item, async.Future)) return false;
      if (dart.is(item, async.Future)) {
        let done = dart.dcall(unittest._wrapAsync, dart.fn(fn => dart.dcall(fn)));
        item.then(dart.dynamic)(dart.fn(value => {
          dart.dcall(done, dart.fn(() => {
            unittest.fail(`Expected future to fail, but succeeded with '${value}'.`);
          }));
        }), {onError: dart.fn((error, trace) => {
            dart.dcall(done, dart.fn(() => {
              if (this[_matcher] == null) return;
              let reason = null;
              if (trace != null) {
                let stackTrace = dart.toString(trace);
                stackTrace = `  ${stackTrace[dartx.replaceAll]("\n", "\n  ")}`;
                reason = `Actual exception trace:\n${stackTrace}`;
              }
              unittest.expect(error, this[_matcher], {reason: dart.as(reason, core.String)});
            }));
          })});
        return true;
      }
      try {
        dart.dcall(item);
        return false;
      } catch (e) {
        let s = dart.stackTrace(e);
        if (this[_matcher] == null || dart.notNull(this[_matcher].matches(e, matchState))) {
          return true;
        } else {
          src__util.addStateInfo(matchState, dart.map({exception: e, stack: s}));
          return false;
        }
      }

    }
    describe(description) {
      if (this[_matcher] == null) {
        return description.add("throws");
      } else {
        return description.add('throws ').addDescriptionOf(this[_matcher]);
      }
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!dart.is(item, core.Function) && !dart.is(item, async.Future)) {
        return mismatchDescription.add('is not a Function or Future');
      } else if (this[_matcher] == null || matchState[dartx.get]('exception') == null) {
        return mismatchDescription.add('did not throw');
      } else {
        mismatchDescription.add('threw ').addDescriptionOf(matchState[dartx.get]('exception'));
        if (dart.notNull(verbose)) {
          mismatchDescription.add(' at ').add(dart.toString(matchState[dartx.get]('stack')));
        }
        return mismatchDescription;
      }
    }
  };
  dart.setSignature(unittest.Throws, {
    constructors: () => ({Throws: [unittest.Throws, [], [src__interfaces.Matcher]]}),
    methods: () => ({
      matches: [core.bool, [dart.dynamic, core.Map]],
      describe: [src__interfaces.Description, [src__interfaces.Description]]
    })
  });
  unittest.throws = dart.const(new unittest.Throws());
  unittest.throwsA = function(matcher) {
    return new unittest.Throws(src__util.wrapMatcher(matcher));
  };
  dart.fn(unittest.throwsA, src__interfaces.Matcher, [dart.dynamic]);
  unittest.group = function(name, body) {
    return js.context.callMethod('suite', dart.list([name, body], core.Object));
  };
  dart.fn(unittest.group, dart.void, [core.String, dart.functionType(dart.void, [])]);
  unittest.test = function(name, body, opts) {
    let skip = opts && 'skip' in opts ? opts.skip : null;
    if (skip != null) {
      core.print(`SKIP ${name}: ${skip}`);
      return;
    }
    let result = dart.as(js.context.callMethod('test', dart.list([name, dart.fn(done => {
        function _finishTest(f) {
          if (dart.is(f, async.Future)) {
            f.then(dart.dynamic)(_finishTest);
          } else {
            done.apply([]);
          }
        }
        dart.fn(_finishTest);
        _finishTest(body());
      }, dart.dynamic, [js.JsFunction])], core.Object)), js.JsObject);
    result.set('async', 1);
  };
  dart.fn(unittest.test, dart.void, [core.String, dart.functionType(dart.dynamic, [])], {skip: core.String});
  unittest.TestFailure = class TestFailure extends core.Object {
    TestFailure(message) {
      this.message = message;
    }
    toString() {
      return this.message;
    }
  };
  dart.setSignature(unittest.TestFailure, {
    constructors: () => ({TestFailure: [unittest.TestFailure, [core.String]]})
  });
  unittest.TestCase = class TestCase extends core.Object {
    get isComplete() {
      return !dart.notNull(this.enabled) || this.result != null;
    }
  };
  unittest.ErrorFormatter = dart.typedef('ErrorFormatter', () => dart.functionType(core.String, [dart.dynamic, src__interfaces.Matcher, core.String, core.Map, core.bool]));
  unittest.expect = function(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let verbose = opts && 'verbose' in opts ? opts.verbose : false;
    let formatter = opts && 'formatter' in opts ? opts.formatter : null;
    matcher = src__util.wrapMatcher(matcher);
    let matchState = dart.map();
    try {
      if (dart.notNull(dart.as(dart.dsend(matcher, 'matches', actual, matchState), core.bool))) return;
    } catch (e) {
      let trace = dart.stackTrace(e);
      if (reason == null) {
        reason = `${typeof e == 'string' ? e : dart.toString(e)} at ${trace}`;
      }
    }

    if (formatter == null) formatter = unittest._defaultFailFormatter;
    unittest.fail(dart.dcall(formatter, actual, matcher, reason, matchState, verbose));
  };
  dart.fn(unittest.expect, dart.void, [dart.dynamic, dart.dynamic], {reason: core.String, verbose: core.bool, formatter: unittest.ErrorFormatter});
  unittest.fail = function(message) {
    return dart.throw(new unittest.TestFailure(message));
  };
  dart.fn(unittest.fail, dart.void, [core.String]);
  unittest._defaultFailFormatter = function(actual, matcher, reason, matchState, verbose) {
    let description = new src__description.StringDescription();
    description.add('Expected: ').addDescriptionOf(matcher).add('\n');
    description.add('  Actual: ').addDescriptionOf(actual).add('\n');
    let mismatchDescription = new src__description.StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);
    if (dart.notNull(mismatchDescription.length) > 0) {
      description.add(`   Which: ${mismatchDescription}\n`);
    }
    if (reason != null) description.add(reason).add('\n');
    return description.toString();
  };
  dart.fn(unittest._defaultFailFormatter, core.String, [dart.dynamic, src__interfaces.Matcher, core.String, core.Map, core.bool]);
  unittest.useHtmlConfiguration = function(isLayoutTest) {
    if (isLayoutTest === void 0) isLayoutTest = false;
  };
  dart.fn(unittest.useHtmlConfiguration, dart.void, [], [core.bool]);
  dart.export(unittest, src__numeric_matchers, 'isPositive');
  dart.export(unittest, src__error_matchers, 'isRangeError');
  dart.export(unittest, src__error_matchers, 'isStateError');
  unittest.equals = src__core_matchers.equals;
  unittest.CustomMatcher = src__core_matchers.CustomMatcher;
  unittest.inOpenClosedRange = src__numeric_matchers.inOpenClosedRange;
  unittest.pairwiseCompare = src__iterable_matchers.pairwiseCompare;
  unittest.equalsIgnoringCase = src__string_matchers.equalsIgnoringCase;
  dart.export(unittest, src__error_matchers, 'isUnimplementedError');
  unittest.hasLength = src__core_matchers.hasLength;
  unittest.StringDescription = src__description.StringDescription;
  unittest.allOf = src__operator_matchers.allOf;
  dart.export(unittest, src__numeric_matchers, 'isNegative');
  unittest.isInstanceOf$ = src__core_matchers.isInstanceOf$;
  unittest.isInstanceOf = src__core_matchers.isInstanceOf;
  dart.export(unittest, src__core_matchers, 'isNaN');
  unittest.lessThan = src__numeric_matchers.lessThan;
  dart.export(unittest, src__core_matchers, 'isNotEmpty');
  unittest.greaterThanOrEqualTo = src__numeric_matchers.greaterThanOrEqualTo;
  unittest.endsWith = src__string_matchers.endsWith;
  dart.export(unittest, src__error_matchers, 'isConcurrentModificationError');
  unittest.containsValue = src__map_matchers.containsValue;
  dart.export(unittest, src__core_matchers, 'isFalse');
  dart.export(unittest, src__core_matchers, 'isTrue');
  unittest.Matcher = src__interfaces.Matcher;
  unittest.lessThanOrEqualTo = src__numeric_matchers.lessThanOrEqualTo;
  unittest.matches = src__string_matchers.matches;
  dart.export(unittest, src__core_matchers, 'returnsNormally');
  unittest.TypeMatcher = src__core_matchers.TypeMatcher;
  unittest.inExclusiveRange = src__numeric_matchers.inExclusiveRange;
  unittest.equalsIgnoringWhitespace = src__string_matchers.equalsIgnoringWhitespace;
  unittest.isIn = src__core_matchers.isIn;
  dart.export(unittest, src__core_matchers, 'isNotNaN');
  dart.export(unittest, src__numeric_matchers, 'isNonZero');
  unittest.startsWith = src__string_matchers.startsWith;
  dart.export(unittest, src__error_matchers, 'isNullThrownError');
  dart.export(unittest, src__core_matchers, 'isEmpty');
  unittest.anyOf = src__operator_matchers.anyOf;
  unittest.unorderedMatches = src__iterable_matchers.unorderedMatches;
  dart.export(unittest, src__numeric_matchers, 'isZero');
  dart.export(unittest, src__core_matchers, 'isList');
  unittest.escape = src__util.escape;
  dart.export(unittest, src__error_matchers, 'isCyclicInitializationError');
  unittest.anyElement = src__iterable_matchers.anyElement;
  dart.export(unittest, src__core_matchers, 'anything');
  unittest.contains = src__core_matchers.contains;
  dart.export(unittest, src__error_matchers, 'isUnsupportedError');
  dart.export(unittest, src__numeric_matchers, 'isNonPositive');
  unittest.isNot = src__operator_matchers.isNot;
  unittest.same = src__core_matchers.same;
  unittest.inClosedOpenRange = src__numeric_matchers.inClosedOpenRange;
  unittest.predicate = src__core_matchers.predicate;
  dart.export(unittest, src__core_matchers, 'isNotNull');
  unittest.wrapMatcher = src__util.wrapMatcher;
  dart.export(unittest, src__error_matchers, 'isNoSuchMethodError');
  unittest.unorderedEquals = src__iterable_matchers.unorderedEquals;
  unittest.everyElement = src__iterable_matchers.everyElement;
  unittest.addStateInfo = src__util.addStateInfo;
  dart.export(unittest, src__error_matchers, 'isArgumentError');
  dart.export(unittest, src__error_matchers, 'isException');
  unittest.inInclusiveRange = src__numeric_matchers.inInclusiveRange;
  unittest.containsPair = src__map_matchers.containsPair;
  dart.export(unittest, src__error_matchers, 'isFormatException');
  unittest.orderedEquals = src__iterable_matchers.orderedEquals;
  unittest.collapseWhitespace = src__string_matchers.collapseWhitespace;
  unittest.greaterThan = src__numeric_matchers.greaterThan;
  dart.export(unittest, src__numeric_matchers, 'isNonNegative');
  dart.export(unittest, src__core_matchers, 'isNull');
  dart.export(unittest, src__core_matchers, 'isMap');
  unittest.stringContainsInOrder = src__string_matchers.stringContainsInOrder;
  unittest.closeTo = src__numeric_matchers.closeTo;
  unittest.Description = src__interfaces.Description;
  // Exports:
  exports.unittest = unittest;
});
