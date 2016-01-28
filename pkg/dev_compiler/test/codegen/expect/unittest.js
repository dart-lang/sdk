dart_library.library('unittest', null, /* Imports */[
  'dart/_runtime',
  'matcher/matcher',
  'dom/dom',
  'dart/core',
  'dart/async',
  'matcher/src/interfaces',
  'matcher/src/util',
  'matcher/src/description'
], /* Lazy imports */[
], function(exports, dart, matcher, dom, core, async, interfaces, util, description$) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, matcher);
  function group(name, body) {
    return dart.dsend(dom.window, 'suite', name, body);
  }
  dart.fn(group, dart.void, [core.String, dart.functionType(dart.void, [])]);
  function test(name, body, opts) {
    let skip = opts && 'skip' in opts ? opts.skip : null;
    if (skip != null) {
      core.print(`SKIP ${name}: ${skip}`);
      return;
    }
    dart.dsend(dom.window, 'test', name, dart.fn(done => {
      function _finishTest(f) {
        if (dart.is(f, async.Future)) {
          f.then(_finishTest);
        } else {
          dart.dcall(done);
        }
      }
      dart.fn(_finishTest);
      _finishTest(body());
    }));
  }
  dart.fn(test, dart.void, [core.String, dart.functionType(dart.dynamic, [])], {skip: core.String});
  class TestFailure extends core.Object {
    TestFailure(message) {
      this.message = message;
    }
    toString() {
      return this.message;
    }
  }
  dart.setSignature(TestFailure, {
    constructors: () => ({TestFailure: [TestFailure, [core.String]]})
  });
  const ErrorFormatter = dart.typedef('ErrorFormatter', () => dart.functionType(core.String, [dart.dynamic, interfaces.Matcher, core.String, core.Map, core.bool]));
  function expect(actual, matcher, opts) {
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

    if (formatter == null) formatter = _defaultFailFormatter;
    fail(dart.dcall(formatter, actual, matcher, reason, matchState, verbose));
  }
  dart.fn(expect, dart.void, [dart.dynamic, dart.dynamic], {reason: core.String, verbose: core.bool, formatter: ErrorFormatter});
  function fail(message) {
    return dart.throw(new TestFailure(message));
  }
  dart.fn(fail, dart.void, [core.String]);
  function _defaultFailFormatter(actual, matcher, reason, matchState, verbose) {
    let description = new description$.StringDescription();
    description.add('Expected: ').addDescriptionOf(matcher).add('\n');
    description.add('  Actual: ').addDescriptionOf(actual).add('\n');
    let mismatchDescription = new description$.StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);
    if (dart.notNull(mismatchDescription.length) > 0) {
      description.add(`   Which: ${mismatchDescription}\n`);
    }
    if (reason != null) description.add(reason).add('\n');
    return dart.toString(description);
  }
  dart.fn(_defaultFailFormatter, core.String, [dart.dynamic, interfaces.Matcher, core.String, core.Map, core.bool]);
  // Exports:
  exports.group = group;
  exports.test = test;
  exports.TestFailure = TestFailure;
  exports.ErrorFormatter = ErrorFormatter;
  exports.expect = expect;
  exports.fail = fail;
});
