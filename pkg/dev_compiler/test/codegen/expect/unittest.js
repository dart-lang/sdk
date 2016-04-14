dart_library.library('unittest', null, /* Imports */[
  'dart_sdk',
  'matcher'
], function(exports, dart_sdk, matcher) {
  'use strict';
  const core = dart_sdk.core;
  const js = dart_sdk.js;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const interfaces = matcher.interfaces;
  const util = matcher.util;
  const description$ = matcher.description;
  const numeric_matchers = matcher.numeric_matchers;
  const error_matchers = matcher.error_matchers;
  const core_matchers = matcher.core_matchers;
  const iterable_matchers = matcher.iterable_matchers;
  const string_matchers = matcher.string_matchers;
  const operator_matchers = matcher.operator_matchers;
  const map_matchers = matcher.map_matchers;
  const unittest = Object.create(null);
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
            f.then(_finishTest);
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
  unittest.ErrorFormatter = dart.typedef('ErrorFormatter', () => dart.functionType(core.String, [dart.dynamic, interfaces.Matcher, core.String, core.Map, core.bool]));
  unittest.expect = function(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let verbose = opts && 'verbose' in opts ? opts.verbose : false;
    let formatter = opts && 'formatter' in opts ? opts.formatter : null;
    matcher = util.wrapMatcher(matcher);
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
    let description = new description$.StringDescription();
    description.add('Expected: ').addDescriptionOf(matcher).add('\n');
    description.add('  Actual: ').addDescriptionOf(actual).add('\n');
    let mismatchDescription = new description$.StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);
    if (dart.notNull(mismatchDescription.length) > 0) {
      description.add(`   Which: ${mismatchDescription}\n`);
    }
    if (reason != null) description.add(reason).add('\n');
    return description.toString();
  };
  dart.fn(unittest._defaultFailFormatter, core.String, [dart.dynamic, interfaces.Matcher, core.String, core.Map, core.bool]);
  unittest.isPositive = numeric_matchers.isPositive;
  unittest.isRangeError = error_matchers.isRangeError;
  unittest.isStateError = error_matchers.isStateError;
  unittest.equals = core_matchers.equals;
  unittest.CustomMatcher = core_matchers.CustomMatcher;
  unittest.inOpenClosedRange = numeric_matchers.inOpenClosedRange;
  unittest.pairwiseCompare = iterable_matchers.pairwiseCompare;
  unittest.equalsIgnoringCase = string_matchers.equalsIgnoringCase;
  unittest.isUnimplementedError = error_matchers.isUnimplementedError;
  unittest.hasLength = core_matchers.hasLength;
  unittest.StringDescription = description$.StringDescription;
  unittest.allOf = operator_matchers.allOf;
  unittest.isNegative = numeric_matchers.isNegative;
  unittest.isInstanceOf$ = core_matchers.isInstanceOf$;
  unittest.isInstanceOf = core_matchers.isInstanceOf;
  unittest.isNaN = core_matchers.isNaN;
  unittest.lessThan = numeric_matchers.lessThan;
  unittest.isNotEmpty = core_matchers.isNotEmpty;
  unittest.greaterThanOrEqualTo = numeric_matchers.greaterThanOrEqualTo;
  unittest.endsWith = string_matchers.endsWith;
  unittest.isConcurrentModificationError = error_matchers.isConcurrentModificationError;
  unittest.containsValue = map_matchers.containsValue;
  unittest.isFalse = core_matchers.isFalse;
  unittest.isTrue = core_matchers.isTrue;
  unittest.Matcher = interfaces.Matcher;
  unittest.lessThanOrEqualTo = numeric_matchers.lessThanOrEqualTo;
  unittest.matches = string_matchers.matches;
  unittest.returnsNormally = core_matchers.returnsNormally;
  unittest.TypeMatcher = core_matchers.TypeMatcher;
  unittest.inExclusiveRange = numeric_matchers.inExclusiveRange;
  unittest.equalsIgnoringWhitespace = string_matchers.equalsIgnoringWhitespace;
  unittest.isIn = core_matchers.isIn;
  unittest.isNotNaN = core_matchers.isNotNaN;
  unittest.isNonZero = numeric_matchers.isNonZero;
  unittest.startsWith = string_matchers.startsWith;
  unittest.isNullThrownError = error_matchers.isNullThrownError;
  unittest.isEmpty = core_matchers.isEmpty;
  unittest.anyOf = operator_matchers.anyOf;
  unittest.unorderedMatches = iterable_matchers.unorderedMatches;
  unittest.isZero = numeric_matchers.isZero;
  unittest.isList = core_matchers.isList;
  unittest.escape = util.escape;
  unittest.isCyclicInitializationError = error_matchers.isCyclicInitializationError;
  unittest.anyElement = iterable_matchers.anyElement;
  unittest.anything = core_matchers.anything;
  unittest.contains = core_matchers.contains;
  unittest.isUnsupportedError = error_matchers.isUnsupportedError;
  unittest.isNonPositive = numeric_matchers.isNonPositive;
  unittest.isNot = operator_matchers.isNot;
  unittest.same = core_matchers.same;
  unittest.inClosedOpenRange = numeric_matchers.inClosedOpenRange;
  unittest.predicate = core_matchers.predicate;
  unittest.isNotNull = core_matchers.isNotNull;
  unittest.wrapMatcher = util.wrapMatcher;
  unittest.isNoSuchMethodError = error_matchers.isNoSuchMethodError;
  unittest.unorderedEquals = iterable_matchers.unorderedEquals;
  unittest.everyElement = iterable_matchers.everyElement;
  unittest.addStateInfo = util.addStateInfo;
  unittest.isArgumentError = error_matchers.isArgumentError;
  unittest.isException = error_matchers.isException;
  unittest.inInclusiveRange = numeric_matchers.inInclusiveRange;
  unittest.containsPair = map_matchers.containsPair;
  unittest.isFormatException = error_matchers.isFormatException;
  unittest.orderedEquals = iterable_matchers.orderedEquals;
  unittest.collapseWhitespace = string_matchers.collapseWhitespace;
  unittest.greaterThan = numeric_matchers.greaterThan;
  unittest.isNonNegative = numeric_matchers.isNonNegative;
  unittest.isNull = core_matchers.isNull;
  unittest.isMap = core_matchers.isMap;
  unittest.stringContainsInOrder = string_matchers.stringContainsInOrder;
  unittest.closeTo = numeric_matchers.closeTo;
  unittest.Description = interfaces.Description;
  // Exports:
  exports.unittest = unittest;
});
