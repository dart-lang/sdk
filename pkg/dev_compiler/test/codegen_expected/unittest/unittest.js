dart_library.library('unittest', null, /* Imports */[
  'dart_sdk',
  'stack_trace'
], function load__unittest(exports, dart_sdk, stack_trace) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const isolate = dart_sdk.isolate;
  const html = dart_sdk.html;
  const convert = dart_sdk.convert;
  const js = dart_sdk.js;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__trace = stack_trace.src__trace;
  const src__frame = stack_trace.src__frame;
  const unittest = Object.create(null);
  const src__configuration = Object.create(null);
  const src__simple_configuration = Object.create(null);
  const src__matcher = Object.create(null);
  const src__matcher__core_matchers = Object.create(null);
  const src__matcher__description = Object.create(null);
  const src__matcher__interfaces = Object.create(null);
  const src__matcher__pretty_print = Object.create(null);
  const src__matcher__util = Object.create(null);
  const src__matcher__error_matchers = Object.create(null);
  const src__matcher__expect = Object.create(null);
  const src__matcher__future_matchers = Object.create(null);
  const src__matcher__iterable_matchers = Object.create(null);
  const src__matcher__map_matchers = Object.create(null);
  const src__matcher__numeric_matchers = Object.create(null);
  const src__matcher__operator_matchers = Object.create(null);
  const src__matcher__prints_matcher = Object.create(null);
  const src__matcher__string_matchers = Object.create(null);
  const src__matcher__throws_matcher = Object.create(null);
  const src__matcher__throws_matchers = Object.create(null);
  const src__internal_test_case = Object.create(null);
  const src__test_environment = Object.create(null);
  const src__group_context = Object.create(null);
  const src__utils = Object.create(null);
  const src__test_case = Object.create(null);
  const src__expected_function = Object.create(null);
  const html_config = Object.create(null);
  const html_individual_config = Object.create(null);
  const html_enhanced_config = Object.create(null);
  let UnmodifiableListViewOfTestCase = () => (UnmodifiableListViewOfTestCase = dart.constFn(collection.UnmodifiableListView$(src__test_case.TestCase)))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.functionType(core.bool, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let isInstanceOf = () => (isInstanceOf = dart.constFn(src__matcher__core_matchers.isInstanceOf$()))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let PairOfString$StackTrace = () => (PairOfString$StackTrace = dart.constFn(src__utils.Pair$(core.String, core.StackTrace)))();
  let JSArrayOfPairOfString$StackTrace = () => (JSArrayOfPairOfString$StackTrace = dart.constFn(_interceptors.JSArray$(PairOfString$StackTrace())))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ListOfbool = () => (ListOfbool = dart.constFn(core.List$(core.bool)))();
  let ListOfMatcher = () => (ListOfMatcher = dart.constFn(core.List$(src__matcher__interfaces.Matcher)))();
  let ListOfInternalTestCase = () => (ListOfInternalTestCase = dart.constFn(core.List$(src__internal_test_case.InternalTestCase)))();
  let Pair = () => (Pair = dart.constFn(src__utils.Pair$()))();
  let ListOfTestCase = () => (ListOfTestCase = dart.constFn(core.List$(src__test_case.TestCase)))();
  let LinkedHashMapOfString$ListOfTestCase = () => (LinkedHashMapOfString$ListOfTestCase = dart.constFn(collection.LinkedHashMap$(core.String, ListOfTestCase())))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let StringAndTestFunctionTovoid = () => (StringAndTestFunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, unittest.TestFunction])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let Function__ToFunction = () => (Function__ToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [core.Function], {count: core.int, max: core.int, id: core.String, reason: core.String})))();
  let FunctionAndFn__ToFunction = () => (FunctionAndFn__ToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [core.Function, VoidTobool()], {id: core.String, reason: core.String})))();
  let StringAndFnTovoid = () => (StringAndFnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, VoidTovoid()])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAndString__Tovoid = () => (dynamicAndString__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, core.String], [dart.dynamic])))();
  let InternalTestCaseTobool = () => (InternalTestCaseTobool = dart.constFn(dart.definiteFunctionType(core.bool, [src__internal_test_case.InternalTestCase])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.StackTrace])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamic__ToFunction = () => (dynamic__ToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [dart.dynamic], [dart.dynamic])))();
  let boolTovoid = () => (boolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let int__Tovoid = () => (int__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int], {enable: core.bool})))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidTodynamic()])))();
  let __ToErrorFormatter = () => (__ToErrorFormatter = dart.constFn(dart.definiteFunctionType(src__matcher__expect.ErrorFormatter, [], [src__matcher__expect.ErrorFormatter])))();
  let dynamic__ToMatcher = () => (dynamic__ToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dart.dynamic], [core.int])))();
  let IterableAndFnAndStringToMatcher = () => (IterableAndFnAndStringToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [core.Iterable, dynamicAnddynamicTobool(), core.String])))();
  let dynamicToMatcher = () => (dynamicToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dart.dynamic])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], {reason: core.String, failureHandler: src__matcher__expect.FailureHandler, verbose: core.bool})))();
  let String__Tovoid = () => (String__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String], {failureHandler: src__matcher__expect.FailureHandler})))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let numAndnumToMatcher = () => (numAndnumToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [core.num, core.num])))();
  let StringToMatcher = () => (StringToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [core.String])))();
  let IterableToMatcher = () => (IterableToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [core.Iterable])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let Function__ToFunction$ = () => (Function__ToFunction$ = dart.constFn(dart.definiteFunctionType(core.Function, [core.Function], [dart.dynamic])))();
  let Fn__ToMatcher = () => (Fn__ToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dynamicTobool()], [core.String])))();
  let MapAndMapTovoid = () => (MapAndMapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map, core.Map])))();
  let dynamic__ToMatcher$ = () => (dynamic__ToMatcher$ = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dart.dynamic], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidToFailureHandler = () => (VoidToFailureHandler = dart.constFn(dart.definiteFunctionType(src__matcher__expect.FailureHandler, [])))();
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], [src__matcher__expect.FailureHandler])))();
  let dynamic__ToMatcher$0 = () => (dynamic__ToMatcher$0 = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dart.dynamic], [core.String])))();
  let dynamicAnddynamicToMatcher = () => (dynamicAnddynamicToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [dart.dynamic, dart.dynamic])))();
  let ListOfStringToMatcher = () => (ListOfStringToMatcher = dart.constFn(dart.definiteFunctionType(src__matcher__interfaces.Matcher, [ListOfString()])))();
  let dynamicTobool$ = () => (dynamicTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let dynamicAndintAndSet__ToString = () => (dynamicAndintAndSet__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic, core.int, core.Set, core.bool])))();
  let dynamic__ToString = () => (dynamic__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic], {maxLineLength: core.int, maxItems: core.int})))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let dynamicAndMatcherAndString__ToString = () => (dynamicAndMatcherAndString__ToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic, src__matcher__interfaces.Matcher, core.String, core.Map, core.bool])))();
  let dynamicAnddynamicAnddynamic__ToListOfMatcher = () => (dynamicAnddynamicAnddynamic__ToListOfMatcher = dart.constFn(dart.definiteFunctionType(ListOfMatcher(), [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let ZoneAndZoneDelegateAndZone__Tovoid = () => (ZoneAndZoneDelegateAndZone__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.String])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let dynamicToFuture = () => (dynamicToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [dart.dynamic])))();
  let FrameTobool = () => (FrameTobool = dart.constFn(dart.definiteFunctionType(core.bool, [src__frame.Frame])))();
  let dynamicAndboolAndboolToTrace = () => (dynamicAndboolAndboolToTrace = dart.constFn(dart.definiteFunctionType(src__trace.Trace, [dart.dynamic, core.bool, core.bool])))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let intAndintAndint__Tovoid = () => (intAndintAndint__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int, core.int, ListOfTestCase(), core.bool, core.String])))();
  let TestCaseToString = () => (TestCaseToString = dart.constFn(dart.definiteFunctionType(core.String, [src__test_case.TestCase])))();
  let MessageEventTovoid = () => (MessageEventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.MessageEvent])))();
  let __Tovoid$ = () => (__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.bool])))();
  let TestCaseTobool = () => (TestCaseTobool = dart.constFn(dart.definiteFunctionType(core.bool, [src__test_case.TestCase])))();
  let ElementToString = () => (ElementToString = dart.constFn(dart.definiteFunctionType(core.String, [html.Element])))();
  let MouseEventTovoid = () => (MouseEventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.MouseEvent])))();
  let TestCaseAndTestCaseToint = () => (TestCaseAndTestCaseToint = dart.constFn(dart.definiteFunctionType(core.int, [src__test_case.TestCase, src__test_case.TestCase])))();
  let ListOfTestCaseTovoid = () => (ListOfTestCaseTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfTestCase()])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  unittest.TestFunction = dart.typedef('TestFunction', () => dart.functionType(dart.dynamic, []));
  dart.copyProperties(unittest, {
    get unittestConfiguration() {
      if (src__test_environment.config == null) src__test_environment.environment.config = src__configuration.Configuration.new();
      return src__test_environment.config;
    },
    set unittestConfiguration(value) {
      if (core.identical(src__test_environment.config, value)) return;
      if (src__test_environment.config != null) {
        unittest.logMessage('Warning: The unittestConfiguration has already been set. New ' + 'unittestConfiguration ignored.');
      } else {
        src__test_environment.environment.config = value;
      }
    }
  });
  unittest.formatStacks = true;
  unittest.filterStacks = true;
  unittest.groupSep = ' ';
  unittest.logMessage = function(message) {
    return src__test_environment.config.onLogMessage(unittest.currentTestCase, message);
  };
  dart.fn(unittest.logMessage, StringTovoid());
  dart.copyProperties(unittest, {
    get testCases() {
      return new (UnmodifiableListViewOfTestCase())(src__test_environment.environment.testCases);
    }
  });
  unittest.BREATH_INTERVAL = 200;
  dart.copyProperties(unittest, {
    get currentTestCase() {
      return dart.notNull(src__test_environment.environment.currentTestCaseIndex) >= 0 && dart.notNull(src__test_environment.environment.currentTestCaseIndex) < dart.notNull(unittest.testCases[dartx.length]) ? unittest.testCases[dartx.get](src__test_environment.environment.currentTestCaseIndex) : null;
    }
  });
  dart.copyProperties(unittest, {
    get _currentTestCase() {
      return src__internal_test_case.InternalTestCase.as(unittest.currentTestCase);
    }
  });
  unittest.PASS = 'pass';
  unittest.FAIL = 'fail';
  unittest.ERROR = 'error';
  unittest.test = function(description, body) {
    unittest._requireNotRunning();
    unittest.ensureInitialized();
    if (dart.test(src__test_environment.environment.soloTestSeen) && src__test_environment.environment.soloNestingLevel == 0) return;
    let testCase = new src__internal_test_case.InternalTestCase(dart.notNull(unittest.testCases[dartx.length]) + 1, unittest._fullDescription(description), body);
    src__test_environment.environment.testCases[dartx.add](testCase);
  };
  dart.fn(unittest.test, StringAndTestFunctionTovoid());
  unittest._fullDescription = function(description) {
    let group = src__test_environment.environment.currentContext.fullName;
    if (description == null) return group;
    return group != '' ? dart.str`${group}${unittest.groupSep}${description}` : description;
  };
  dart.fn(unittest._fullDescription, StringToString());
  unittest.skip_test = function(spec, body) {
  };
  dart.fn(unittest.skip_test, StringAndTestFunctionTovoid());
  unittest.solo_test = function(spec, body) {
    unittest._requireNotRunning();
    unittest.ensureInitialized();
    if (!dart.test(src__test_environment.environment.soloTestSeen)) {
      src__test_environment.environment.soloTestSeen = true;
      src__test_environment.environment.testCases[dartx.clear]();
    }
    let o = src__test_environment.environment;
    o.soloNestingLevel = dart.notNull(o.soloNestingLevel) + 1;
    try {
      unittest.test(spec, body);
    } finally {
      let o$ = src__test_environment.environment;
      o$.soloNestingLevel = dart.notNull(o$.soloNestingLevel) - 1;
    }
  };
  dart.fn(unittest.solo_test, StringAndTestFunctionTovoid());
  unittest.expectAsync = function(callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return new src__expected_function.ExpectedFunction(callback, count, max, {id: id, reason: reason}).func;
  };
  dart.fn(unittest.expectAsync, Function__ToFunction());
  unittest.expectAsyncUntil = function(callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return new src__expected_function.ExpectedFunction(callback, 0, -1, {id: id, reason: reason, isDone: isDone}).func;
  };
  dart.fn(unittest.expectAsyncUntil, FunctionAndFn__ToFunction());
  unittest.group = function(description, body) {
    unittest.ensureInitialized();
    unittest._requireNotRunning();
    src__test_environment.environment.currentContext = new src__group_context.GroupContext(src__test_environment.environment.currentContext, description);
    try {
      body();
    } catch (e) {
      let trace = dart.stackTrace(e);
      let stack = trace == null ? '' : dart.str`: ${trace.toString()}`;
      src__test_environment.environment.uncaughtErrorMessage = dart.str`${dart.toString(e)}${stack}`;
    }
 finally {
      src__test_environment.environment.currentContext = src__test_environment.environment.currentContext.parent;
    }
  };
  dart.fn(unittest.group, StringAndFnTovoid());
  unittest.skip_group = function(description, body) {
  };
  dart.fn(unittest.skip_group, StringAndFnTovoid());
  unittest.solo_group = function(description, body) {
    unittest._requireNotRunning();
    unittest.ensureInitialized();
    if (!dart.test(src__test_environment.environment.soloTestSeen)) {
      src__test_environment.environment.soloTestSeen = true;
      src__test_environment.environment.testCases[dartx.clear]();
    }
    let o = src__test_environment.environment;
    o.soloNestingLevel = dart.notNull(o.soloNestingLevel) + 1;
    try {
      unittest.group(description, body);
    } finally {
      let o$ = src__test_environment.environment;
      o$.soloNestingLevel = dart.notNull(o$.soloNestingLevel) - 1;
    }
  };
  dart.fn(unittest.solo_group, StringAndFnTovoid());
  unittest.setUp = function(callback) {
    unittest._requireNotRunning();
    src__test_environment.environment.currentContext.testSetUp = callback;
  };
  dart.fn(unittest.setUp, FunctionTovoid());
  unittest.tearDown = function(callback) {
    unittest._requireNotRunning();
    src__test_environment.environment.currentContext.testTearDown = callback;
  };
  dart.fn(unittest.tearDown, FunctionTovoid());
  unittest._nextTestCase = function() {
    let o = src__test_environment.environment;
    o.currentTestCaseIndex = dart.notNull(o.currentTestCaseIndex) + 1;
    unittest._runTest();
  };
  dart.fn(unittest._nextTestCase, VoidTovoid$());
  unittest.handleExternalError = function(e, message, stackTrace) {
    if (stackTrace === void 0) stackTrace = null;
    let msg = dart.str`${message}\nCaught ${e}`;
    if (unittest.currentTestCase != null) {
      unittest._currentTestCase.error(msg, core.StackTrace._check(stackTrace));
    } else {
      src__test_environment.environment.uncaughtErrorMessage = dart.str`${msg}: ${stackTrace}`;
    }
  };
  dart.fn(unittest.handleExternalError, dynamicAndString__Tovoid());
  unittest._TestFilter = dart.typedef('_TestFilter', () => dart.functionType(core.bool, [src__internal_test_case.InternalTestCase]));
  unittest.filterTests = function(testFilter) {
    let filterFunction = null;
    if (typeof testFilter == 'string') {
      let re = core.RegExp.new(testFilter);
      filterFunction = dart.fn(t => re.hasMatch(t.description), InternalTestCaseTobool());
    } else if (core.RegExp.is(testFilter)) {
      filterFunction = dart.fn(t => testFilter.hasMatch(t.description), InternalTestCaseTobool());
    } else if (unittest._TestFilter.is(testFilter)) {
      filterFunction = testFilter;
    }
    src__test_environment.environment.testCases[dartx.retainWhere](filterFunction);
  };
  dart.fn(unittest.filterTests, dynamicTovoid());
  unittest.runTests = function() {
    unittest._requireNotRunning();
    unittest._ensureInitialized(false);
    src__test_environment.environment.currentTestCaseIndex = 0;
    src__test_environment.config.onStart();
    unittest._runTest();
  };
  dart.fn(unittest.runTests, VoidTovoid$());
  unittest.registerException = function(error, stackTrace) {
    if (stackTrace === void 0) stackTrace = null;
    return unittest._currentTestCase.registerException(error, stackTrace);
  };
  dart.fn(unittest.registerException, dynamic__Tovoid());
  unittest._runTest = function() {
    if (dart.notNull(src__test_environment.environment.currentTestCaseIndex) >= dart.notNull(unittest.testCases[dartx.length])) {
      dart.assert(src__test_environment.environment.currentTestCaseIndex == unittest.testCases[dartx.length]);
      unittest._completeTests();
      return;
    }
    let testCase = unittest._currentTestCase;
    let f = async.runZoned(async.Future)(dart.bind(testCase, 'run'), {onError: dart.fn((error, stack) => {
        testCase.registerException(error, core.StackTrace._check(stack));
      }, dynamicAnddynamicTodynamic())});
    let timer = null;
    let timeout = unittest.unittestConfiguration.timeout;
    if (timeout != null) {
      try {
        timer = async.Timer.new(timeout, dart.fn(() => {
          testCase.error(dart.str`Test timed out after ${timeout.inSeconds} seconds.`);
          unittest._nextTestCase();
        }, VoidTovoid$()));
      } catch (e) {
        if (core.UnsupportedError.is(e)) {
          if (e.message != "Timer greater than 0.") throw e;
        } else
          throw e;
      }

    }
    f.whenComplete(dart.fn(() => {
      if (timer != null) dart.dsend(timer, 'cancel');
      let now = new core.DateTime.now().millisecondsSinceEpoch;
      if (dart.notNull(now) - dart.notNull(src__test_environment.environment.lastBreath) >= unittest.BREATH_INTERVAL) {
        src__test_environment.environment.lastBreath = now;
        async.Timer.run(unittest._nextTestCase);
      } else {
        async.scheduleMicrotask(unittest._nextTestCase);
      }
    }, VoidTodynamic$()));
  };
  dart.fn(unittest._runTest, VoidTovoid$());
  unittest._completeTests = function() {
    if (!dart.test(src__test_environment.environment.initialized)) return;
    let passed = 0;
    let failed = 0;
    let errors = 0;
    for (let testCase of unittest.testCases) {
      switch (testCase.result) {
        case unittest.PASS:
        {
          passed++;
          break;
        }
        case unittest.FAIL:
        {
          failed++;
          break;
        }
        case unittest.ERROR:
        {
          errors++;
          break;
        }
      }
    }
    src__test_environment.config.onSummary(passed, failed, errors, unittest.testCases, src__test_environment.environment.uncaughtErrorMessage);
    src__test_environment.config.onDone(passed > 0 && failed == 0 && errors == 0 && src__test_environment.environment.uncaughtErrorMessage == null);
    src__test_environment.environment.initialized = false;
    src__test_environment.environment.currentTestCaseIndex = -1;
  };
  dart.fn(unittest._completeTests, VoidTovoid$());
  unittest.ensureInitialized = function() {
    unittest._ensureInitialized(true);
  };
  dart.fn(unittest.ensureInitialized, VoidTovoid$());
  unittest._ensureInitialized = function(configAutoStart) {
    if (dart.test(src__test_environment.environment.initialized)) return;
    src__test_environment.environment.initialized = true;
    src__matcher__expect.wrapAsync = dart.fn((f, id) => {
      if (id === void 0) id = null;
      return unittest.expectAsync(core.Function._check(f), {id: core.String._check(id)});
    }, dynamic__ToFunction());
    src__test_environment.environment.uncaughtErrorMessage = null;
    unittest.unittestConfiguration.onInit();
    if (dart.test(configAutoStart) && dart.test(src__test_environment.config.autoStart)) async.scheduleMicrotask(unittest.runTests);
  };
  dart.fn(unittest._ensureInitialized, boolTovoid());
  unittest.setSoloTest = function(id) {
    return src__test_environment.environment.testCases[dartx.retainWhere](dart.fn(t => t.id == id, InternalTestCaseTobool()));
  };
  dart.fn(unittest.setSoloTest, intTovoid());
  unittest.enableTest = function(id) {
    return unittest._setTestEnabledState(id, {enable: true});
  };
  dart.fn(unittest.enableTest, intTovoid());
  unittest.disableTest = function(id) {
    return unittest._setTestEnabledState(id, {enable: false});
  };
  dart.fn(unittest.disableTest, intTovoid());
  unittest._setTestEnabledState = function(id, opts) {
    let enable = opts && 'enable' in opts ? opts.enable : true;
    if (dart.notNull(unittest.testCases[dartx.length]) > dart.notNull(id) && unittest.testCases[dartx.get](id).id == id) {
      src__test_environment.environment.testCases[dartx.get](id).enabled = enable;
    } else {
      for (let i = 0; i < dart.notNull(unittest.testCases[dartx.length]); i++) {
        if (unittest.testCases[dartx.get](i).id != id) continue;
        src__test_environment.environment.testCases[dartx.get](i).enabled = enable;
        break;
      }
    }
  };
  dart.fn(unittest._setTestEnabledState, int__Tovoid());
  unittest._requireNotRunning = function() {
    if (src__test_environment.environment.currentTestCaseIndex == -1) return;
    dart.throw(new core.StateError('Not allowed when tests are running.'));
  };
  dart.fn(unittest._requireNotRunning, VoidTovoid$());
  let const$;
  unittest.withTestEnvironment = function(callback) {
    return async.runZoned(dart.dynamic)(callback, {zoneValues: dart.map([const$ || (const$ = dart.const(core.Symbol.new('unittest.environment'))), new src__test_environment.TestEnvironment()], core.Symbol, src__test_environment.TestEnvironment)});
  };
  dart.fn(unittest.withTestEnvironment, FnTodynamic());
  let const$0;
  src__configuration.Configuration = class Configuration extends core.Object {
    static new() {
      return new src__simple_configuration.SimpleConfiguration();
    }
    blank() {
      this.autoStart = true;
      this.timeout = const$0 || (const$0 = dart.const(new core.Duration({minutes: 2})));
    }
    onInit() {}
    onStart() {}
    onTestStart(testCase) {}
    onTestResult(testCase) {}
    onTestResultChanged(testCase) {}
    onLogMessage(testCase, message) {}
    onDone(success) {}
    onSummary(passed, failed, errors, results, uncaughtError) {}
  };
  dart.defineNamedConstructor(src__configuration.Configuration, 'blank');
  dart.setSignature(src__configuration.Configuration, {
    constructors: () => ({
      new: dart.definiteFunctionType(src__configuration.Configuration, []),
      blank: dart.definiteFunctionType(src__configuration.Configuration, [])
    }),
    methods: () => ({
      onInit: dart.definiteFunctionType(dart.void, []),
      onStart: dart.definiteFunctionType(dart.void, []),
      onTestStart: dart.definiteFunctionType(dart.void, [src__test_case.TestCase]),
      onTestResult: dart.definiteFunctionType(dart.void, [src__test_case.TestCase]),
      onTestResultChanged: dart.definiteFunctionType(dart.void, [src__test_case.TestCase]),
      onLogMessage: dart.definiteFunctionType(dart.void, [src__test_case.TestCase, core.String]),
      onDone: dart.definiteFunctionType(dart.void, [core.bool]),
      onSummary: dart.definiteFunctionType(dart.void, [core.int, core.int, core.int, core.List$(src__test_case.TestCase), core.String])
    })
  });
  unittest.Configuration = src__configuration.Configuration;
  src__matcher__expect.configureExpectFormatter = function(formatter) {
    if (formatter === void 0) formatter = null;
    if (formatter == null) {
      formatter = src__matcher__expect._defaultErrorFormatter;
    }
    return src__matcher__expect._assertErrorFormatter = formatter;
  };
  dart.lazyFn(src__matcher__expect.configureExpectFormatter, () => __ToErrorFormatter());
  unittest.configureExpectFormatter = src__matcher__expect.configureExpectFormatter;
  const _name = Symbol('_name');
  src__matcher__interfaces.Matcher = class Matcher extends core.Object {
    new() {
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      return mismatchDescription;
    }
  };
  dart.setSignature(src__matcher__interfaces.Matcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__interfaces.Matcher, [])}),
    methods: () => ({describeMismatch: dart.definiteFunctionType(src__matcher__interfaces.Description, [dart.dynamic, src__matcher__interfaces.Description, core.Map, core.bool])})
  });
  src__matcher__core_matchers.TypeMatcher = class TypeMatcher extends src__matcher__interfaces.Matcher {
    new(name) {
      this[_name] = name;
      super.new();
    }
    describe(description) {
      return description.add(this[_name]);
    }
  };
  dart.setSignature(src__matcher__core_matchers.TypeMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers.TypeMatcher, [core.String])}),
    methods: () => ({describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])})
  });
  src__matcher__error_matchers._RangeError = class _RangeError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("RangeError");
    }
    matches(item, matchState) {
      return core.RangeError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._RangeError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._RangeError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isRangeError = dart.const(new src__matcher__error_matchers._RangeError());
  unittest.isRangeError = src__matcher__error_matchers.isRangeError;
  src__matcher__error_matchers._StateError = class _StateError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("StateError");
    }
    matches(item, matchState) {
      return core.StateError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._StateError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._StateError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isStateError = dart.const(new src__matcher__error_matchers._StateError());
  unittest.isStateError = src__matcher__error_matchers.isStateError;
  src__matcher__core_matchers.equals = function(expected, limit) {
    if (limit === void 0) limit = 100;
    return typeof expected == 'string' ? new src__matcher__core_matchers._StringEqualsMatcher(expected) : new src__matcher__core_matchers._DeepMatcher(expected, limit);
  };
  dart.fn(src__matcher__core_matchers.equals, dynamic__ToMatcher());
  unittest.equals = src__matcher__core_matchers.equals;
  const _featureDescription = Symbol('_featureDescription');
  const _featureName = Symbol('_featureName');
  const _matcher = Symbol('_matcher');
  src__matcher__core_matchers.CustomMatcher = class CustomMatcher extends src__matcher__interfaces.Matcher {
    new(featureDescription, featureName, matcher) {
      this[_featureDescription] = featureDescription;
      this[_featureName] = featureName;
      this[_matcher] = src__matcher__util.wrapMatcher(matcher);
      super.new();
    }
    featureValueOf(actual) {
      return actual;
    }
    matches(item, matchState) {
      let f = this.featureValueOf(item);
      if (dart.test(this[_matcher].matches(f, matchState))) return true;
      src__matcher__util.addStateInfo(matchState, dart.map({feature: f}, core.String, dart.dynamic));
      return false;
    }
    describe(description) {
      return description.add(this[_featureDescription]).add(' ').addDescriptionOf(this[_matcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('has ').add(this[_featureName]).add(' with value ').addDescriptionOf(matchState[dartx.get]('feature'));
      let innerDescription = new src__matcher__description.StringDescription();
      this[_matcher].describeMismatch(matchState[dartx.get]('feature'), innerDescription, core.Map._check(matchState[dartx.get]('state')), verbose);
      if (dart.notNull(innerDescription.length) > 0) {
        mismatchDescription.add(' which ').add(innerDescription.toString());
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__matcher__core_matchers.CustomMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers.CustomMatcher, [core.String, core.String, dart.dynamic])}),
    methods: () => ({
      featureValueOf: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  unittest.CustomMatcher = src__matcher__core_matchers.CustomMatcher;
  src__matcher__iterable_matchers.pairwiseCompare = function(expected, comparator, description) {
    return new src__matcher__iterable_matchers._PairwiseCompare(expected, comparator, description);
  };
  dart.fn(src__matcher__iterable_matchers.pairwiseCompare, IterableAndFnAndStringToMatcher());
  unittest.pairwiseCompare = src__matcher__iterable_matchers.pairwiseCompare;
  src__matcher__error_matchers._UnimplementedError = class _UnimplementedError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("UnimplementedError");
    }
    matches(item, matchState) {
      return core.UnimplementedError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._UnimplementedError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._UnimplementedError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isUnimplementedError = dart.const(new src__matcher__error_matchers._UnimplementedError());
  unittest.isUnimplementedError = src__matcher__error_matchers.isUnimplementedError;
  src__matcher__core_matchers.hasLength = function(matcher) {
    return new src__matcher__core_matchers._HasLength(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__core_matchers.hasLength, dynamicToMatcher());
  unittest.hasLength = src__matcher__core_matchers.hasLength;
  src__matcher__expect.expect = function(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let failureHandler = opts && 'failureHandler' in opts ? opts.failureHandler : null;
    let verbose = opts && 'verbose' in opts ? opts.verbose : false;
    matcher = src__matcher__util.wrapMatcher(matcher);
    let doesMatch = null;
    let matchState = dart.map();
    try {
      doesMatch = core.bool._check(dart.dsend(matcher, 'matches', actual, matchState));
    } catch (e) {
      let trace = dart.stackTrace(e);
      doesMatch = false;
      if (reason == null) {
        reason = dart.str`${typeof e == 'string' ? e : dart.toString(e)} at ${trace}`;
      }
    }

    if (!dart.test(doesMatch)) {
      if (failureHandler == null) {
        failureHandler = src__matcher__expect.getOrCreateExpectFailureHandler();
      }
      failureHandler.failMatch(actual, src__matcher__interfaces.Matcher._check(matcher), reason, matchState, verbose);
    }
  };
  dart.lazyFn(src__matcher__expect.expect, () => dynamicAnddynamic__Tovoid());
  unittest.expect = src__matcher__expect.expect;
  const _out = Symbol('_out');
  src__matcher__description.StringDescription = class StringDescription extends core.Object {
    new(init) {
      if (init === void 0) init = '';
      this[_out] = new core.StringBuffer();
      this[_out].write(init);
    }
    get length() {
      return this[_out].length;
    }
    toString() {
      return dart.toString(this[_out]);
    }
    add(text) {
      this[_out].write(text);
      return this;
    }
    replace(text) {
      this[_out].clear();
      return this.add(text);
    }
    addDescriptionOf(value) {
      if (src__matcher__interfaces.Matcher.is(value)) {
        value.describe(this);
      } else {
        this.add(src__matcher__pretty_print.prettyPrint(value, {maxLineLength: 80, maxItems: 25}));
      }
      return this;
    }
    addAll(start, separator, end, list) {
      let separate = false;
      this.add(start);
      for (let item of list) {
        if (separate) {
          this.add(separator);
        }
        this.addDescriptionOf(item);
        separate = true;
      }
      this.add(end);
      return this;
    }
  };
  src__matcher__description.StringDescription[dart.implements] = () => [src__matcher__interfaces.Description];
  dart.setSignature(src__matcher__description.StringDescription, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__description.StringDescription, [], [core.String])}),
    methods: () => ({
      add: dart.definiteFunctionType(src__matcher__interfaces.Description, [core.String]),
      replace: dart.definiteFunctionType(src__matcher__interfaces.Description, [core.String]),
      addDescriptionOf: dart.definiteFunctionType(src__matcher__interfaces.Description, [dart.dynamic]),
      addAll: dart.definiteFunctionType(src__matcher__interfaces.Description, [core.String, core.String, core.String, core.Iterable])
    })
  });
  unittest.StringDescription = src__matcher__description.StringDescription;
  src__matcher__expect.fail = function(message, opts) {
    let failureHandler = opts && 'failureHandler' in opts ? opts.failureHandler : null;
    if (failureHandler == null) {
      failureHandler = src__matcher__expect.getOrCreateExpectFailureHandler();
    }
    failureHandler.fail(message);
  };
  dart.lazyFn(src__matcher__expect.fail, () => String__Tovoid());
  unittest.fail = src__matcher__expect.fail;
  src__matcher__core_matchers._IsNaN = class _IsNaN extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.double.NAN[dartx.compareTo](core.num._check(item)) == 0;
    }
    describe(description) {
      return description.add('NaN');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsNaN, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsNaN, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isNaN = dart.const(new src__matcher__core_matchers._IsNaN());
  unittest.isNaN = src__matcher__core_matchers.isNaN;
  src__matcher__core_matchers.isInstanceOf$ = dart.generic(T => {
    class isInstanceOf extends src__matcher__interfaces.Matcher {
      new(name) {
        if (name === void 0) name = null;
        super.new();
      }
      matches(obj, matchState) {
        return T.is(obj);
      }
      describe(description) {
        return description.add(dart.str`an instance of ${dart.wrapType(T)}`);
      }
    }
    dart.addTypeTests(isInstanceOf);
    dart.setSignature(isInstanceOf, {
      constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers.isInstanceOf$(T), [], [core.String])}),
      methods: () => ({
        matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
        describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
      })
    });
    return isInstanceOf;
  });
  src__matcher__core_matchers.isInstanceOf = isInstanceOf();
  unittest.isInstanceOf$ = src__matcher__core_matchers.isInstanceOf$;
  unittest.isInstanceOf = src__matcher__core_matchers.isInstanceOf;
  const _matcher$ = Symbol('_matcher');
  src__matcher__throws_matcher.Throws = class Throws extends src__matcher__interfaces.Matcher {
    new(matcher) {
      if (matcher === void 0) matcher = null;
      this[_matcher$] = matcher;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Function.is(item) && !async.Future.is(item)) return false;
      if (async.Future.is(item)) {
        let done = dart.dcall(src__matcher__expect.wrapAsync, dart.fn(fn => dart.dcall(fn), dynamicTodynamic()));
        item.then(dart.dynamic)(dart.fn(value => {
          dart.dcall(done, dart.fn(() => {
            src__matcher__expect.fail(dart.str`Expected future to fail, but succeeded with '${value}'.`);
          }, VoidTodynamic$()));
        }, dynamicTodynamic()), {onError: dart.fn((error, trace) => {
            dart.dcall(done, dart.fn(() => {
              if (this[_matcher$] == null) return;
              let reason = null;
              if (trace != null) {
                let stackTrace = dart.toString(trace);
                stackTrace = dart.str`  ${stackTrace[dartx.replaceAll]("\n", "\n  ")}`;
                reason = dart.str`Actual exception trace:\n${stackTrace}`;
              }
              src__matcher__expect.expect(error, this[_matcher$], {reason: core.String._check(reason)});
            }, VoidTodynamic$()));
          }, dynamicAnddynamicTodynamic())});
        return true;
      }
      try {
        dart.dcall(item);
        return false;
      } catch (e) {
        let s = dart.stackTrace(e);
        if (this[_matcher$] == null || dart.test(this[_matcher$].matches(e, matchState))) {
          return true;
        } else {
          src__matcher__util.addStateInfo(matchState, dart.map({exception: e, stack: s}, core.String, dart.dynamic));
          return false;
        }
      }

    }
    describe(description) {
      if (this[_matcher$] == null) {
        return description.add("throws");
      } else {
        return description.add('throws ').addDescriptionOf(this[_matcher$]);
      }
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Function.is(item) && !async.Future.is(item)) {
        return mismatchDescription.add('is not a Function or Future');
      } else if (this[_matcher$] == null || matchState[dartx.get]('exception') == null) {
        return mismatchDescription.add('did not throw');
      } else {
        mismatchDescription.add('threw ').addDescriptionOf(matchState[dartx.get]('exception'));
        if (dart.test(verbose)) {
          mismatchDescription.add(' at ').add(dart.toString(matchState[dartx.get]('stack')));
        }
        return mismatchDescription;
      }
    }
  };
  dart.setSignature(src__matcher__throws_matcher.Throws, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__throws_matcher.Throws, [], [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__error_matchers._CyclicInitializationError = class _CyclicInitializationError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("CyclicInitializationError");
    }
    matches(item, matchState) {
      return core.CyclicInitializationError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._CyclicInitializationError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._CyclicInitializationError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isCyclicInitializationError = dart.const(new src__matcher__error_matchers._CyclicInitializationError());
  src__matcher__throws_matchers.throwsCyclicInitializationError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isCyclicInitializationError));
  unittest.throwsCyclicInitializationError = src__matcher__throws_matchers.throwsCyclicInitializationError;
  const _matcher$0 = Symbol('_matcher');
  const _id = Symbol('_id');
  src__matcher__future_matchers._Completes = class _Completes extends src__matcher__interfaces.Matcher {
    new(matcher, id) {
      this[_matcher$0] = matcher;
      this[_id] = id;
      super.new();
    }
    matches(item, matchState) {
      if (!async.Future.is(item)) return false;
      let done = dart.dcall(src__matcher__expect.wrapAsync, dart.fn(fn => dart.dcall(fn), dynamicTodynamic()), this[_id]);
      dart.dsend(item, 'then', dart.fn(value => {
        dart.dcall(done, dart.fn(() => {
          if (this[_matcher$0] != null) src__matcher__expect.expect(value, this[_matcher$0]);
        }, VoidTodynamic$()));
      }, dynamicTodynamic()), {onError: dart.fn((error, trace) => {
          let id = this[_id] == '' ? '' : dart.str`${this[_id]} `;
          let reason = dart.str`Expected future ${id}to complete successfully, ` + dart.str`but it failed with ${error}`;
          if (trace != null) {
            let stackTrace = dart.toString(trace);
            stackTrace = dart.str`  ${stackTrace[dartx.replaceAll]('\n', '\n  ')}`;
            reason = dart.str`${reason}\nStack trace:\n${stackTrace}`;
          }
          dart.dcall(done, dart.fn(() => src__matcher__expect.fail(reason), VoidTovoid$()));
        }, dynamicAnddynamicTodynamic())});
      return true;
    }
    describe(description) {
      if (this[_matcher$0] == null) {
        description.add('completes successfully');
      } else {
        description.add('completes to a value that ').addDescriptionOf(this[_matcher$0]);
      }
      return description;
    }
  };
  dart.setSignature(src__matcher__future_matchers._Completes, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__future_matchers._Completes, [src__matcher__interfaces.Matcher, core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__future_matchers.completes = dart.const(new src__matcher__future_matchers._Completes(null, ''));
  unittest.completes = src__matcher__future_matchers.completes;
  src__matcher__core_matchers._NotEmpty = class _NotEmpty extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dload(item, 'isNotEmpty'));
    }
    describe(description) {
      return description.add('non-empty');
    }
  };
  dart.setSignature(src__matcher__core_matchers._NotEmpty, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._NotEmpty, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isNotEmpty = dart.const(new src__matcher__core_matchers._NotEmpty());
  unittest.isNotEmpty = src__matcher__core_matchers.isNotEmpty;
  src__matcher__error_matchers._ConcurrentModificationError = class _ConcurrentModificationError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("ConcurrentModificationError");
    }
    matches(item, matchState) {
      return core.ConcurrentModificationError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._ConcurrentModificationError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._ConcurrentModificationError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isConcurrentModificationError = dart.const(new src__matcher__error_matchers._ConcurrentModificationError());
  unittest.isConcurrentModificationError = src__matcher__error_matchers.isConcurrentModificationError;
  src__matcher__throws_matcher.throwsA = function(matcher) {
    return new src__matcher__throws_matcher.Throws(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__throws_matcher.throwsA, dynamicToMatcher());
  unittest.throwsA = src__matcher__throws_matcher.throwsA;
  src__matcher__core_matchers._IsTrue = class _IsTrue extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return dart.equals(item, true);
    }
    describe(description) {
      return description.add('true');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsTrue, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsTrue, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isTrue = dart.const(new src__matcher__core_matchers._IsTrue());
  unittest.isTrue = src__matcher__core_matchers.isTrue;
  src__matcher__throws_matchers.throwsRangeError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isRangeError));
  unittest.throwsRangeError = src__matcher__throws_matchers.throwsRangeError;
  src__matcher__expect.ErrorFormatter = dart.typedef('ErrorFormatter', () => dart.functionType(core.String, [dart.dynamic, src__matcher__interfaces.Matcher, core.String, core.Map, core.bool]));
  unittest.ErrorFormatter = src__matcher__expect.ErrorFormatter;
  src__matcher__error_matchers._FormatException = class _FormatException extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("FormatException");
    }
    matches(item, matchState) {
      return core.FormatException.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._FormatException, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._FormatException, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isFormatException = dart.const(new src__matcher__error_matchers._FormatException());
  src__matcher__throws_matchers.throwsFormatException = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isFormatException));
  unittest.throwsFormatException = src__matcher__throws_matchers.throwsFormatException;
  src__matcher__core_matchers._ReturnsNormally = class _ReturnsNormally extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(f, matchState) {
      try {
        dart.dcall(f);
        return true;
      } catch (e) {
        let s = dart.stackTrace(e);
        src__matcher__util.addStateInfo(matchState, dart.map({exception: e, stack: s}, core.String, dart.dynamic));
        return false;
      }

    }
    describe(description) {
      return description.add("return normally");
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('threw ').addDescriptionOf(matchState[dartx.get]('exception'));
      if (dart.test(verbose)) {
        mismatchDescription.add(' at ').add(dart.toString(matchState[dartx.get]('stack')));
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__matcher__core_matchers._ReturnsNormally, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._ReturnsNormally, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.returnsNormally = dart.const(new src__matcher__core_matchers._ReturnsNormally());
  unittest.returnsNormally = src__matcher__core_matchers.returnsNormally;
  src__matcher__numeric_matchers.inExclusiveRange = function(low, high) {
    return new src__matcher__numeric_matchers._InRange(low, high, false, false);
  };
  dart.fn(src__matcher__numeric_matchers.inExclusiveRange, numAndnumToMatcher());
  unittest.inExclusiveRange = src__matcher__numeric_matchers.inExclusiveRange;
  src__matcher__core_matchers.isIn = function(expected) {
    return new src__matcher__core_matchers._In(expected);
  };
  dart.fn(src__matcher__core_matchers.isIn, dynamicToMatcher());
  unittest.isIn = src__matcher__core_matchers.isIn;
  src__matcher__string_matchers.equalsIgnoringWhitespace = function(value) {
    return new src__matcher__string_matchers._IsEqualIgnoringWhitespace(value);
  };
  dart.fn(src__matcher__string_matchers.equalsIgnoringWhitespace, StringToMatcher());
  unittest.equalsIgnoringWhitespace = src__matcher__string_matchers.equalsIgnoringWhitespace;
  src__matcher__string_matchers.startsWith = function(prefixString) {
    return new src__matcher__string_matchers._StringStartsWith(prefixString);
  };
  dart.fn(src__matcher__string_matchers.startsWith, StringToMatcher());
  unittest.startsWith = src__matcher__string_matchers.startsWith;
  src__matcher__iterable_matchers.unorderedMatches = function(expected) {
    return new src__matcher__iterable_matchers._UnorderedMatches(expected);
  };
  dart.fn(src__matcher__iterable_matchers.unorderedMatches, IterableToMatcher());
  unittest.unorderedMatches = src__matcher__iterable_matchers.unorderedMatches;
  const _value = Symbol('_value');
  const _equalValue = Symbol('_equalValue');
  const _lessThanValue = Symbol('_lessThanValue');
  const _greaterThanValue = Symbol('_greaterThanValue');
  const _comparisonDescription = Symbol('_comparisonDescription');
  const _valueInDescription = Symbol('_valueInDescription');
  src__matcher__numeric_matchers._OrderingComparison = class _OrderingComparison extends src__matcher__interfaces.Matcher {
    new(value, equalValue, lessThanValue, greaterThanValue, comparisonDescription, valueInDescription) {
      if (valueInDescription === void 0) valueInDescription = true;
      this[_value] = value;
      this[_equalValue] = equalValue;
      this[_lessThanValue] = lessThanValue;
      this[_greaterThanValue] = greaterThanValue;
      this[_comparisonDescription] = comparisonDescription;
      this[_valueInDescription] = valueInDescription;
      super.new();
    }
    matches(item, matchState) {
      if (dart.equals(item, this[_value])) {
        return this[_equalValue];
      } else if (dart.test(dart.dsend(item, '<', this[_value]))) {
        return this[_lessThanValue];
      } else {
        return this[_greaterThanValue];
      }
    }
    describe(description) {
      if (dart.test(this[_valueInDescription])) {
        return description.add(this[_comparisonDescription]).add(' ').addDescriptionOf(this[_value]);
      } else {
        return description.add(this[_comparisonDescription]);
      }
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      mismatchDescription.add('is not ');
      return this.describe(mismatchDescription);
    }
  };
  dart.setSignature(src__matcher__numeric_matchers._OrderingComparison, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__numeric_matchers._OrderingComparison, [dart.dynamic, core.bool, core.bool, core.bool, core.String], [core.bool])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__numeric_matchers.isZero = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, true, false, false, 'a value equal to'));
  unittest.isZero = src__matcher__numeric_matchers.isZero;
  src__matcher__core_matchers._IsList = class _IsList extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("List");
    }
    matches(item, matchState) {
      return core.List.is(item);
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsList, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsList, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__core_matchers.isList = dart.const(new src__matcher__core_matchers._IsList());
  unittest.isList = src__matcher__core_matchers.isList;
  src__matcher__prints_matcher.prints = function(matcher) {
    return new src__matcher__prints_matcher._Prints(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__prints_matcher.prints, dynamicToMatcher());
  unittest.prints = src__matcher__prints_matcher.prints;
  src__matcher__util.escape = function(str) {
    str = str[dartx.replaceAll]('\\', '\\\\');
    return str[dartx.replaceAllMapped](src__matcher__util._escapeRegExp, dart.fn(match => {
      let mapped = src__matcher__util._escapeMap[dartx.get](match.get(0));
      if (mapped != null) return mapped;
      return src__matcher__util._getHexLiteral(match.get(0));
    }, MatchToString()));
  };
  dart.fn(src__matcher__util.escape, StringToString());
  unittest.escape = src__matcher__util.escape;
  src__matcher__iterable_matchers.anyElement = function(matcher) {
    return new src__matcher__iterable_matchers._AnyElement(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__iterable_matchers.anyElement, dynamicToMatcher());
  unittest.anyElement = src__matcher__iterable_matchers.anyElement;
  src__matcher__error_matchers._Exception = class _Exception extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("Exception");
    }
    matches(item, matchState) {
      return core.Exception.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._Exception, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._Exception, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isException = dart.const(new src__matcher__error_matchers._Exception());
  src__matcher__throws_matchers.throwsException = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isException));
  unittest.throwsException = src__matcher__throws_matchers.throwsException;
  src__matcher__core_matchers._IsAnything = class _IsAnything extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return true;
    }
    describe(description) {
      return description.add('anything');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsAnything, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsAnything, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.anything = dart.const(new src__matcher__core_matchers._IsAnything());
  unittest.anything = src__matcher__core_matchers.anything;
  src__matcher__core_matchers.contains = function(expected) {
    return new src__matcher__core_matchers._Contains(expected);
  };
  dart.fn(src__matcher__core_matchers.contains, dynamicToMatcher());
  unittest.contains = src__matcher__core_matchers.contains;
  src__matcher__operator_matchers.isNot = function(matcher) {
    return new src__matcher__operator_matchers._IsNot(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__operator_matchers.isNot, dynamicToMatcher());
  unittest.isNot = src__matcher__operator_matchers.isNot;
  dart.defineLazy(src__matcher__expect, {
    get wrapAsync() {
      return dart.fn((f, id) => {
        if (id === void 0) id = null;
        return f;
      }, Function__ToFunction$());
    },
    set wrapAsync(_) {}
  });
  dart.export(unittest, src__matcher__expect, 'wrapAsync');
  src__matcher__core_matchers.same = function(expected) {
    return new src__matcher__core_matchers._IsSameAs(expected);
  };
  dart.fn(src__matcher__core_matchers.same, dynamicToMatcher());
  unittest.same = src__matcher__core_matchers.same;
  src__matcher__numeric_matchers.inClosedOpenRange = function(low, high) {
    return new src__matcher__numeric_matchers._InRange(low, high, true, false);
  };
  dart.fn(src__matcher__numeric_matchers.inClosedOpenRange, numAndnumToMatcher());
  unittest.inClosedOpenRange = src__matcher__numeric_matchers.inClosedOpenRange;
  src__matcher__core_matchers.predicate = function(f, description) {
    if (description === void 0) description = 'satisfies function';
    return new src__matcher__core_matchers._Predicate(f, description);
  };
  dart.fn(src__matcher__core_matchers.predicate, Fn__ToMatcher());
  unittest.predicate = src__matcher__core_matchers.predicate;
  src__matcher__util.wrapMatcher = function(x) {
    if (src__matcher__interfaces.Matcher.is(x)) {
      return x;
    } else if (src__matcher__util._Predicate.is(x)) {
      return src__matcher__core_matchers.predicate(x);
    } else {
      return src__matcher__core_matchers.equals(x);
    }
  };
  dart.fn(src__matcher__util.wrapMatcher, dynamicToMatcher());
  unittest.wrapMatcher = src__matcher__util.wrapMatcher;
  src__matcher__iterable_matchers.unorderedEquals = function(expected) {
    return new src__matcher__iterable_matchers._UnorderedEquals(expected);
  };
  dart.fn(src__matcher__iterable_matchers.unorderedEquals, IterableToMatcher());
  unittest.unorderedEquals = src__matcher__iterable_matchers.unorderedEquals;
  src__matcher__expect.TestFailure = class TestFailure extends core.Error {
    new(message) {
      this.message = message;
      super.new();
    }
    toString() {
      return this.message;
    }
  };
  dart.setSignature(src__matcher__expect.TestFailure, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__expect.TestFailure, [core.String])})
  });
  unittest.TestFailure = src__matcher__expect.TestFailure;
  unittest.isException = src__matcher__error_matchers.isException;
  src__matcher__util.addStateInfo = function(matchState, values) {
    let innerState = core.Map.from(matchState);
    matchState[dartx.clear]();
    matchState[dartx.set]('state', innerState);
    matchState[dartx.addAll](values);
  };
  dart.fn(src__matcher__util.addStateInfo, MapAndMapTovoid());
  unittest.addStateInfo = src__matcher__util.addStateInfo;
  src__matcher__throws_matchers.throwsConcurrentModificationError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isConcurrentModificationError));
  unittest.throwsConcurrentModificationError = src__matcher__throws_matchers.throwsConcurrentModificationError;
  src__matcher__numeric_matchers.closeTo = function(value, delta) {
    return new src__matcher__numeric_matchers._IsCloseTo(value, delta);
  };
  dart.fn(src__matcher__numeric_matchers.closeTo, numAndnumToMatcher());
  unittest.closeTo = src__matcher__numeric_matchers.closeTo;
  src__matcher__numeric_matchers.isPositive = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, false, false, true, 'a positive value', false));
  unittest.isPositive = src__matcher__numeric_matchers.isPositive;
  src__matcher__numeric_matchers.inOpenClosedRange = function(low, high) {
    return new src__matcher__numeric_matchers._InRange(low, high, false, true);
  };
  dart.fn(src__matcher__numeric_matchers.inOpenClosedRange, numAndnumToMatcher());
  unittest.inOpenClosedRange = src__matcher__numeric_matchers.inOpenClosedRange;
  src__matcher__string_matchers.equalsIgnoringCase = function(value) {
    return new src__matcher__string_matchers._IsEqualIgnoringCase(value);
  };
  dart.fn(src__matcher__string_matchers.equalsIgnoringCase, StringToMatcher());
  unittest.equalsIgnoringCase = src__matcher__string_matchers.equalsIgnoringCase;
  src__matcher__numeric_matchers.isNegative = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, false, true, false, 'a negative value', false));
  unittest.isNegative = src__matcher__numeric_matchers.isNegative;
  src__matcher__operator_matchers.allOf = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    if (arg1 === void 0) arg1 = null;
    if (arg2 === void 0) arg2 = null;
    if (arg3 === void 0) arg3 = null;
    if (arg4 === void 0) arg4 = null;
    if (arg5 === void 0) arg5 = null;
    if (arg6 === void 0) arg6 = null;
    return new src__matcher__operator_matchers._AllOf(src__matcher__operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  dart.fn(src__matcher__operator_matchers.allOf, dynamic__ToMatcher$());
  unittest.allOf = src__matcher__operator_matchers.allOf;
  src__matcher__error_matchers._ArgumentError = class _ArgumentError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("ArgumentError");
    }
    matches(item, matchState) {
      return core.ArgumentError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._ArgumentError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._ArgumentError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isArgumentError = dart.const(new src__matcher__error_matchers._ArgumentError());
  src__matcher__throws_matchers.throwsArgumentError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isArgumentError));
  unittest.throwsArgumentError = src__matcher__throws_matchers.throwsArgumentError;
  src__matcher__numeric_matchers.lessThan = function(value) {
    return new src__matcher__numeric_matchers._OrderingComparison(value, false, true, false, 'a value less than');
  };
  dart.fn(src__matcher__numeric_matchers.lessThan, dynamicToMatcher());
  unittest.lessThan = src__matcher__numeric_matchers.lessThan;
  src__matcher__throws_matchers.throwsStateError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isStateError));
  unittest.throwsStateError = src__matcher__throws_matchers.throwsStateError;
  src__matcher__numeric_matchers.greaterThanOrEqualTo = function(value) {
    return new src__matcher__numeric_matchers._OrderingComparison(value, true, false, true, 'a value greater than or equal to');
  };
  dart.fn(src__matcher__numeric_matchers.greaterThanOrEqualTo, dynamicToMatcher());
  unittest.greaterThanOrEqualTo = src__matcher__numeric_matchers.greaterThanOrEqualTo;
  unittest.Throws = src__matcher__throws_matcher.Throws;
  src__matcher__map_matchers.containsValue = function(value) {
    return new src__matcher__map_matchers._ContainsValue(value);
  };
  dart.fn(src__matcher__map_matchers.containsValue, dynamicToMatcher());
  unittest.containsValue = src__matcher__map_matchers.containsValue;
  src__matcher__string_matchers.endsWith = function(suffixString) {
    return new src__matcher__string_matchers._StringEndsWith(suffixString);
  };
  dart.fn(src__matcher__string_matchers.endsWith, StringToMatcher());
  unittest.endsWith = src__matcher__string_matchers.endsWith;
  src__matcher__core_matchers._IsFalse = class _IsFalse extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return dart.equals(item, false);
    }
    describe(description) {
      return description.add('false');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsFalse, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsFalse, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isFalse = dart.const(new src__matcher__core_matchers._IsFalse());
  unittest.isFalse = src__matcher__core_matchers.isFalse;
  unittest.Matcher = src__matcher__interfaces.Matcher;
  src__matcher__numeric_matchers.lessThanOrEqualTo = function(value) {
    return new src__matcher__numeric_matchers._OrderingComparison(value, true, true, false, 'a value less than or equal to');
  };
  dart.fn(src__matcher__numeric_matchers.lessThanOrEqualTo, dynamicToMatcher());
  unittest.lessThanOrEqualTo = src__matcher__numeric_matchers.lessThanOrEqualTo;
  src__matcher__expect.getOrCreateExpectFailureHandler = function() {
    if (src__matcher__expect._assertFailureHandler == null) {
      src__matcher__expect.configureExpectFailureHandler();
    }
    return src__matcher__expect._assertFailureHandler;
  };
  dart.lazyFn(src__matcher__expect.getOrCreateExpectFailureHandler, () => VoidToFailureHandler());
  unittest.getOrCreateExpectFailureHandler = src__matcher__expect.getOrCreateExpectFailureHandler;
  src__matcher__string_matchers.matches = function(re) {
    return new src__matcher__string_matchers._MatchesRegExp(re);
  };
  dart.fn(src__matcher__string_matchers.matches, dynamicToMatcher());
  unittest.matches = src__matcher__string_matchers.matches;
  src__matcher__error_matchers._UnsupportedError = class _UnsupportedError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("UnsupportedError");
    }
    matches(item, matchState) {
      return core.UnsupportedError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._UnsupportedError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._UnsupportedError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isUnsupportedError = dart.const(new src__matcher__error_matchers._UnsupportedError());
  src__matcher__throws_matchers.throwsUnsupportedError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isUnsupportedError));
  unittest.throwsUnsupportedError = src__matcher__throws_matchers.throwsUnsupportedError;
  unittest.TypeMatcher = src__matcher__core_matchers.TypeMatcher;
  src__matcher__expect.configureExpectFailureHandler = function(handler) {
    if (handler === void 0) handler = null;
    if (handler == null) {
      handler = new src__matcher__expect.DefaultFailureHandler();
    }
    src__matcher__expect._assertFailureHandler = handler;
  };
  dart.lazyFn(src__matcher__expect.configureExpectFailureHandler, () => __Tovoid());
  unittest.configureExpectFailureHandler = src__matcher__expect.configureExpectFailureHandler;
  src__matcher__expect.FailureHandler = class FailureHandler extends core.Object {};
  unittest.FailureHandler = src__matcher__expect.FailureHandler;
  src__matcher__core_matchers._IsNotNaN = class _IsNotNaN extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.double.NAN[dartx.compareTo](core.num._check(item)) != 0;
    }
    describe(description) {
      return description.add('not NaN');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsNotNaN, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsNotNaN, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isNotNaN = dart.const(new src__matcher__core_matchers._IsNotNaN());
  unittest.isNotNaN = src__matcher__core_matchers.isNotNaN;
  src__matcher__numeric_matchers.isNonZero = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, false, true, true, 'a value not equal to'));
  unittest.isNonZero = src__matcher__numeric_matchers.isNonZero;
  src__matcher__throws_matcher.throws = dart.const(new src__matcher__throws_matcher.Throws());
  unittest.throws = src__matcher__throws_matcher.throws;
  src__matcher__error_matchers._NullThrownError = class _NullThrownError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("NullThrownError");
    }
    matches(item, matchState) {
      return core.NullThrownError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._NullThrownError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._NullThrownError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isNullThrownError = dart.const(new src__matcher__error_matchers._NullThrownError());
  unittest.isNullThrownError = src__matcher__error_matchers.isNullThrownError;
  src__matcher__expect.DefaultFailureHandler = class DefaultFailureHandler extends core.Object {
    new() {
      if (src__matcher__expect._assertErrorFormatter == null) {
        src__matcher__expect._assertErrorFormatter = src__matcher__expect._defaultErrorFormatter;
      }
    }
    fail(reason) {
      dart.throw(new src__matcher__expect.TestFailure(reason));
    }
    failMatch(actual, matcher, reason, matchState, verbose) {
      this.fail(dart.dcall(src__matcher__expect._assertErrorFormatter, actual, matcher, reason, matchState, verbose));
    }
  };
  src__matcher__expect.DefaultFailureHandler[dart.implements] = () => [src__matcher__expect.FailureHandler];
  dart.setSignature(src__matcher__expect.DefaultFailureHandler, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__expect.DefaultFailureHandler, [])}),
    methods: () => ({
      fail: dart.definiteFunctionType(dart.void, [core.String]),
      failMatch: dart.definiteFunctionType(dart.void, [dart.dynamic, src__matcher__interfaces.Matcher, core.String, core.Map, core.bool])
    })
  });
  unittest.DefaultFailureHandler = src__matcher__expect.DefaultFailureHandler;
  src__matcher__core_matchers._Empty = class _Empty extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dload(item, 'isEmpty'));
    }
    describe(description) {
      return description.add('empty');
    }
  };
  dart.setSignature(src__matcher__core_matchers._Empty, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._Empty, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isEmpty = dart.const(new src__matcher__core_matchers._Empty());
  unittest.isEmpty = src__matcher__core_matchers.isEmpty;
  src__matcher__operator_matchers.anyOf = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    if (arg1 === void 0) arg1 = null;
    if (arg2 === void 0) arg2 = null;
    if (arg3 === void 0) arg3 = null;
    if (arg4 === void 0) arg4 = null;
    if (arg5 === void 0) arg5 = null;
    if (arg6 === void 0) arg6 = null;
    return new src__matcher__operator_matchers._AnyOf(src__matcher__operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  dart.fn(src__matcher__operator_matchers.anyOf, dynamic__ToMatcher$());
  unittest.anyOf = src__matcher__operator_matchers.anyOf;
  unittest.isCyclicInitializationError = src__matcher__error_matchers.isCyclicInitializationError;
  src__matcher__error_matchers._NoSuchMethodError = class _NoSuchMethodError extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("NoSuchMethodError");
    }
    matches(item, matchState) {
      return core.NoSuchMethodError.is(item);
    }
  };
  dart.setSignature(src__matcher__error_matchers._NoSuchMethodError, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__error_matchers._NoSuchMethodError, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__error_matchers.isNoSuchMethodError = dart.const(new src__matcher__error_matchers._NoSuchMethodError());
  src__matcher__throws_matchers.throwsNoSuchMethodError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isNoSuchMethodError));
  unittest.throwsNoSuchMethodError = src__matcher__throws_matchers.throwsNoSuchMethodError;
  src__matcher__future_matchers.completion = function(matcher, id) {
    if (id === void 0) id = '';
    return new src__matcher__future_matchers._Completes(src__matcher__util.wrapMatcher(matcher), id);
  };
  dart.fn(src__matcher__future_matchers.completion, dynamic__ToMatcher$0());
  unittest.completion = src__matcher__future_matchers.completion;
  unittest.isUnsupportedError = src__matcher__error_matchers.isUnsupportedError;
  src__matcher__numeric_matchers.isNonPositive = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, true, true, false, 'a non-positive value', false));
  unittest.isNonPositive = src__matcher__numeric_matchers.isNonPositive;
  dart.export(unittest, src__matcher__expect, 'wrapAsync');
  src__matcher__core_matchers._IsNotNull = class _IsNotNull extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return item != null;
    }
    describe(description) {
      return description.add('not null');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsNotNull, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsNotNull, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isNotNull = dart.const(new src__matcher__core_matchers._IsNotNull());
  unittest.isNotNull = src__matcher__core_matchers.isNotNull;
  unittest.isNoSuchMethodError = src__matcher__error_matchers.isNoSuchMethodError;
  src__matcher__throws_matchers.throwsNullThrownError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isNullThrownError));
  unittest.throwsNullThrownError = src__matcher__throws_matchers.throwsNullThrownError;
  src__matcher__throws_matchers.throwsUnimplementedError = dart.const(new src__matcher__throws_matcher.Throws(src__matcher__error_matchers.isUnimplementedError));
  unittest.throwsUnimplementedError = src__matcher__throws_matchers.throwsUnimplementedError;
  src__matcher__iterable_matchers.everyElement = function(matcher) {
    return new src__matcher__iterable_matchers._EveryElement(src__matcher__util.wrapMatcher(matcher));
  };
  dart.fn(src__matcher__iterable_matchers.everyElement, dynamicToMatcher());
  unittest.everyElement = src__matcher__iterable_matchers.everyElement;
  unittest.isArgumentError = src__matcher__error_matchers.isArgumentError;
  src__matcher__map_matchers.containsPair = function(key, value) {
    return new src__matcher__map_matchers._ContainsMapping(key, src__matcher__util.wrapMatcher(value));
  };
  dart.fn(src__matcher__map_matchers.containsPair, dynamicAnddynamicToMatcher());
  unittest.containsPair = src__matcher__map_matchers.containsPair;
  src__matcher__numeric_matchers.inInclusiveRange = function(low, high) {
    return new src__matcher__numeric_matchers._InRange(low, high, true, true);
  };
  dart.fn(src__matcher__numeric_matchers.inInclusiveRange, numAndnumToMatcher());
  unittest.inInclusiveRange = src__matcher__numeric_matchers.inInclusiveRange;
  unittest.isFormatException = src__matcher__error_matchers.isFormatException;
  src__matcher__iterable_matchers.orderedEquals = function(expected) {
    return new src__matcher__iterable_matchers._OrderedEquals(expected);
  };
  dart.fn(src__matcher__iterable_matchers.orderedEquals, IterableToMatcher());
  unittest.orderedEquals = src__matcher__iterable_matchers.orderedEquals;
  src__matcher__string_matchers.collapseWhitespace = function(string) {
    let result = new core.StringBuffer();
    let skipSpace = true;
    for (let i = 0; i < dart.notNull(string[dartx.length]); i++) {
      let character = string[dartx.get](i);
      if (dart.test(src__matcher__string_matchers._isWhitespace(character))) {
        if (!skipSpace) {
          result.write(' ');
          skipSpace = true;
        }
      } else {
        result.write(character);
        skipSpace = false;
      }
    }
    return result.toString()[dartx.trim]();
  };
  dart.fn(src__matcher__string_matchers.collapseWhitespace, StringToString());
  unittest.collapseWhitespace = src__matcher__string_matchers.collapseWhitespace;
  src__matcher__numeric_matchers.greaterThan = function(value) {
    return new src__matcher__numeric_matchers._OrderingComparison(value, false, false, true, 'a value greater than');
  };
  dart.fn(src__matcher__numeric_matchers.greaterThan, dynamicToMatcher());
  unittest.greaterThan = src__matcher__numeric_matchers.greaterThan;
  src__matcher__numeric_matchers.isNonNegative = dart.const(new src__matcher__numeric_matchers._OrderingComparison(0, true, false, true, 'a non-negative value', false));
  unittest.isNonNegative = src__matcher__numeric_matchers.isNonNegative;
  src__matcher__core_matchers._IsNull = class _IsNull extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    matches(item, matchState) {
      return item == null;
    }
    describe(description) {
      return description.add('null');
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsNull, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsNull, [])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers.isNull = dart.const(new src__matcher__core_matchers._IsNull());
  unittest.isNull = src__matcher__core_matchers.isNull;
  src__matcher__core_matchers._IsMap = class _IsMap extends src__matcher__core_matchers.TypeMatcher {
    new() {
      super.new("Map");
    }
    matches(item, matchState) {
      return core.Map.is(item);
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsMap, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsMap, [])}),
    methods: () => ({matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map])})
  });
  src__matcher__core_matchers.isMap = dart.const(new src__matcher__core_matchers._IsMap());
  unittest.isMap = src__matcher__core_matchers.isMap;
  src__matcher__interfaces.Description = class Description extends core.Object {};
  unittest.Description = src__matcher__interfaces.Description;
  src__matcher__string_matchers.stringContainsInOrder = function(substrings) {
    return new src__matcher__string_matchers._StringContainsInOrder(substrings);
  };
  dart.fn(src__matcher__string_matchers.stringContainsInOrder, ListOfStringToMatcher());
  unittest.stringContainsInOrder = src__matcher__string_matchers.stringContainsInOrder;
  const _testLogBuffer = Symbol('_testLogBuffer');
  const _receivePort = Symbol('_receivePort');
  const _postMessage = Symbol('_postMessage');
  src__simple_configuration.SimpleConfiguration = class SimpleConfiguration extends src__configuration.Configuration {
    new() {
      this[_testLogBuffer] = JSArrayOfPairOfString$StackTrace().of([]);
      this[_receivePort] = null;
      this.name = 'Configuration';
      this.throwOnTestFailures = true;
      this.stopTestOnExpectFailure = true;
      super.blank();
      src__matcher__expect.configureExpectFailureHandler(new src__simple_configuration._ExpectFailureHandler(this));
    }
    onInit() {
      unittest.filterStacks = false;
      this[_receivePort] = isolate.ReceivePort.new();
      this[_postMessage]('unittest-suite-wait-for-done');
    }
    onTestStart(testCase) {
      return this[_testLogBuffer][dartx.clear]();
    }
    onTestResult(externalTestCase) {
      if (dart.test(this.stopTestOnExpectFailure) || dart.test(this[_testLogBuffer][dartx.isEmpty])) return;
      let testCase = src__internal_test_case.InternalTestCase.as(externalTestCase);
      let reason = new core.StringBuffer();
      for (let reasonAndTrace of this[_testLogBuffer][dartx.take](dart.notNull(this[_testLogBuffer][dartx.length]) - 1)) {
        reason.write(reasonAndTrace.first);
        reason.write('\n');
        reason.write(reasonAndTrace.last);
        reason.write('\n');
      }
      let lastReasonAndTrace = this[_testLogBuffer][dartx.last];
      reason.write(lastReasonAndTrace.first);
      if (testCase.result == unittest.PASS) {
        testCase.result = unittest.FAIL;
        testCase.message = reason.toString();
        testCase.stackTrace = lastReasonAndTrace.last;
      } else {
        reason.write(lastReasonAndTrace.last);
        reason.write('\n');
        testCase.message = dart.str`${reason.toString()}\n${testCase.message}`;
      }
    }
    onLogMessage(testCase, message) {
      core.print(message);
    }
    onExpectFailure(reason) {
      if (dart.test(this.stopTestOnExpectFailure)) dart.throw(new src__matcher__expect.TestFailure(reason));
      try {
        dart.throw('');
      } catch (_) {
        let stack = dart.stackTrace(_);
        let trace = src__utils.getTrace(stack, unittest.formatStacks, unittest.filterStacks);
        if (trace == null) trace = src__trace.Trace._check(stack);
        this[_testLogBuffer][dartx.add](new (PairOfString$StackTrace())(reason, trace));
      }

    }
    formatResult(testCase) {
      let result = new core.StringBuffer();
      result.write(testCase.result[dartx.toUpperCase]());
      result.write(": ");
      result.write(testCase.description);
      result.write("\n");
      if (testCase.message != '') {
        result.write(src__utils.indent(testCase.message));
        result.write("\n");
      }
      if (testCase.stackTrace != null) {
        result.write(src__utils.indent(dart.toString(testCase.stackTrace)));
        result.write("\n");
      }
      return result.toString();
    }
    onSummary(passed, failed, errors, results, uncaughtError) {
      for (let test of results) {
        core.print(this.formatResult(test)[dartx.trim]());
      }
      core.print('');
      if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
        core.print('No tests found.');
      } else if (failed == 0 && errors == 0 && uncaughtError == null) {
        core.print(dart.str`All ${passed} tests passed.`);
      } else {
        if (uncaughtError != null) {
          core.print(dart.str`Top-level uncaught error: ${uncaughtError}`);
        }
        core.print(dart.str`${passed} PASSED, ${failed} FAILED, ${errors} ERRORS`);
      }
    }
    onDone(success) {
      if (dart.test(success)) {
        this[_postMessage]('unittest-suite-success');
        this[_receivePort].close();
      } else {
        this[_receivePort].close();
        if (dart.test(this.throwOnTestFailures)) {
          dart.throw(core.Exception.new('Some tests failed.'));
        }
      }
    }
    [_postMessage](message) {
      core.print(message);
    }
  };
  dart.setSignature(src__simple_configuration.SimpleConfiguration, {
    constructors: () => ({new: dart.definiteFunctionType(src__simple_configuration.SimpleConfiguration, [])}),
    methods: () => ({
      onExpectFailure: dart.definiteFunctionType(dart.void, [core.String]),
      formatResult: dart.definiteFunctionType(core.String, [src__test_case.TestCase]),
      [_postMessage]: dart.definiteFunctionType(dart.void, [core.String])
    })
  });
  unittest.SimpleConfiguration = src__simple_configuration.SimpleConfiguration;
  src__test_case.TestCase = class TestCase extends core.Object {
    get isComplete() {
      return !dart.test(this.enabled) || this.result != null;
    }
  };
  unittest.TestCase = src__test_case.TestCase;
  const _config = Symbol('_config');
  src__simple_configuration._ExpectFailureHandler = class _ExpectFailureHandler extends src__matcher__expect.DefaultFailureHandler {
    new(config) {
      this[_config] = config;
      super.new();
    }
    fail(reason) {
      this[_config].onExpectFailure(reason);
    }
  };
  dart.setSignature(src__simple_configuration._ExpectFailureHandler, {
    constructors: () => ({new: dart.definiteFunctionType(src__simple_configuration._ExpectFailureHandler, [src__simple_configuration.SimpleConfiguration])})
  });
  src__matcher.isTrue = src__matcher__core_matchers.isTrue;
  src__matcher.isFalse = src__matcher__core_matchers.isFalse;
  src__matcher.isEmpty = src__matcher__core_matchers.isEmpty;
  src__matcher.same = src__matcher__core_matchers.same;
  src__matcher.equals = src__matcher__core_matchers.equals;
  src__matcher.CustomMatcher = src__matcher__core_matchers.CustomMatcher;
  src__matcher.isList = src__matcher__core_matchers.isList;
  src__matcher.predicate = src__matcher__core_matchers.predicate;
  src__matcher.isNotNull = src__matcher__core_matchers.isNotNull;
  src__matcher.hasLength = src__matcher__core_matchers.hasLength;
  src__matcher.isInstanceOf$ = src__matcher__core_matchers.isInstanceOf$;
  src__matcher.isInstanceOf = src__matcher__core_matchers.isInstanceOf;
  src__matcher.isNaN = src__matcher__core_matchers.isNaN;
  src__matcher.returnsNormally = src__matcher__core_matchers.returnsNormally;
  src__matcher.anything = src__matcher__core_matchers.anything;
  src__matcher.TypeMatcher = src__matcher__core_matchers.TypeMatcher;
  src__matcher.contains = src__matcher__core_matchers.contains;
  src__matcher.isNotEmpty = src__matcher__core_matchers.isNotEmpty;
  src__matcher.isNull = src__matcher__core_matchers.isNull;
  src__matcher.isMap = src__matcher__core_matchers.isMap;
  src__matcher.isNotNaN = src__matcher__core_matchers.isNotNaN;
  src__matcher.isIn = src__matcher__core_matchers.isIn;
  src__matcher.StringDescription = src__matcher__description.StringDescription;
  src__matcher.isConcurrentModificationError = src__matcher__error_matchers.isConcurrentModificationError;
  src__matcher.isCyclicInitializationError = src__matcher__error_matchers.isCyclicInitializationError;
  src__matcher.isArgumentError = src__matcher__error_matchers.isArgumentError;
  src__matcher.isException = src__matcher__error_matchers.isException;
  src__matcher.isNullThrownError = src__matcher__error_matchers.isNullThrownError;
  src__matcher.isRangeError = src__matcher__error_matchers.isRangeError;
  src__matcher.isFormatException = src__matcher__error_matchers.isFormatException;
  src__matcher.isStateError = src__matcher__error_matchers.isStateError;
  src__matcher.isNoSuchMethodError = src__matcher__error_matchers.isNoSuchMethodError;
  src__matcher.isUnimplementedError = src__matcher__error_matchers.isUnimplementedError;
  src__matcher.isUnsupportedError = src__matcher__error_matchers.isUnsupportedError;
  src__matcher.TestFailure = src__matcher__expect.TestFailure;
  src__matcher.configureExpectFormatter = src__matcher__expect.configureExpectFormatter;
  src__matcher.DefaultFailureHandler = src__matcher__expect.DefaultFailureHandler;
  src__matcher.fail = src__matcher__expect.fail;
  src__matcher.ErrorFormatter = src__matcher__expect.ErrorFormatter;
  dart.export(src__matcher, src__matcher__expect, 'wrapAsync');
  dart.export(src__matcher, src__matcher__expect, 'wrapAsync');
  src__matcher.configureExpectFailureHandler = src__matcher__expect.configureExpectFailureHandler;
  src__matcher.FailureHandler = src__matcher__expect.FailureHandler;
  src__matcher.expect = src__matcher__expect.expect;
  src__matcher.getOrCreateExpectFailureHandler = src__matcher__expect.getOrCreateExpectFailureHandler;
  src__matcher.completes = src__matcher__future_matchers.completes;
  src__matcher.completion = src__matcher__future_matchers.completion;
  src__matcher.Matcher = src__matcher__interfaces.Matcher;
  src__matcher.Description = src__matcher__interfaces.Description;
  src__matcher.pairwiseCompare = src__matcher__iterable_matchers.pairwiseCompare;
  src__matcher.anyElement = src__matcher__iterable_matchers.anyElement;
  src__matcher.orderedEquals = src__matcher__iterable_matchers.orderedEquals;
  src__matcher.unorderedEquals = src__matcher__iterable_matchers.unorderedEquals;
  src__matcher.unorderedMatches = src__matcher__iterable_matchers.unorderedMatches;
  src__matcher.everyElement = src__matcher__iterable_matchers.everyElement;
  src__matcher.containsValue = src__matcher__map_matchers.containsValue;
  src__matcher.containsPair = src__matcher__map_matchers.containsPair;
  src__matcher.isPositive = src__matcher__numeric_matchers.isPositive;
  src__matcher.isZero = src__matcher__numeric_matchers.isZero;
  src__matcher.inOpenClosedRange = src__matcher__numeric_matchers.inOpenClosedRange;
  src__matcher.inClosedOpenRange = src__matcher__numeric_matchers.inClosedOpenRange;
  src__matcher.lessThanOrEqualTo = src__matcher__numeric_matchers.lessThanOrEqualTo;
  src__matcher.isNegative = src__matcher__numeric_matchers.isNegative;
  src__matcher.inInclusiveRange = src__matcher__numeric_matchers.inInclusiveRange;
  src__matcher.lessThan = src__matcher__numeric_matchers.lessThan;
  src__matcher.greaterThan = src__matcher__numeric_matchers.greaterThan;
  src__matcher.isNonNegative = src__matcher__numeric_matchers.isNonNegative;
  src__matcher.inExclusiveRange = src__matcher__numeric_matchers.inExclusiveRange;
  src__matcher.closeTo = src__matcher__numeric_matchers.closeTo;
  src__matcher.greaterThanOrEqualTo = src__matcher__numeric_matchers.greaterThanOrEqualTo;
  src__matcher.isNonZero = src__matcher__numeric_matchers.isNonZero;
  src__matcher.isNonPositive = src__matcher__numeric_matchers.isNonPositive;
  src__matcher.allOf = src__matcher__operator_matchers.allOf;
  src__matcher.isNot = src__matcher__operator_matchers.isNot;
  src__matcher.anyOf = src__matcher__operator_matchers.anyOf;
  src__matcher.prints = src__matcher__prints_matcher.prints;
  src__matcher.endsWith = src__matcher__string_matchers.endsWith;
  src__matcher.startsWith = src__matcher__string_matchers.startsWith;
  src__matcher.matches = src__matcher__string_matchers.matches;
  src__matcher.collapseWhitespace = src__matcher__string_matchers.collapseWhitespace;
  src__matcher.equalsIgnoringCase = src__matcher__string_matchers.equalsIgnoringCase;
  src__matcher.equalsIgnoringWhitespace = src__matcher__string_matchers.equalsIgnoringWhitespace;
  src__matcher.stringContainsInOrder = src__matcher__string_matchers.stringContainsInOrder;
  src__matcher.throwsA = src__matcher__throws_matcher.throwsA;
  src__matcher.throws = src__matcher__throws_matcher.throws;
  src__matcher.Throws = src__matcher__throws_matcher.Throws;
  src__matcher.throwsArgumentError = src__matcher__throws_matchers.throwsArgumentError;
  src__matcher.throwsRangeError = src__matcher__throws_matchers.throwsRangeError;
  src__matcher.throwsUnsupportedError = src__matcher__throws_matchers.throwsUnsupportedError;
  src__matcher.throwsCyclicInitializationError = src__matcher__throws_matchers.throwsCyclicInitializationError;
  src__matcher.throwsException = src__matcher__throws_matchers.throwsException;
  src__matcher.throwsNoSuchMethodError = src__matcher__throws_matchers.throwsNoSuchMethodError;
  src__matcher.throwsFormatException = src__matcher__throws_matchers.throwsFormatException;
  src__matcher.throwsStateError = src__matcher__throws_matchers.throwsStateError;
  src__matcher.throwsConcurrentModificationError = src__matcher__throws_matchers.throwsConcurrentModificationError;
  src__matcher.throwsNullThrownError = src__matcher__throws_matchers.throwsNullThrownError;
  src__matcher.throwsUnimplementedError = src__matcher__throws_matchers.throwsUnimplementedError;
  src__matcher.addStateInfo = src__matcher__util.addStateInfo;
  src__matcher.wrapMatcher = src__matcher__util.wrapMatcher;
  src__matcher.escape = src__matcher__util.escape;
  const _expected = Symbol('_expected');
  src__matcher__core_matchers._IsSameAs = class _IsSameAs extends src__matcher__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      return core.identical(item, this[_expected]);
    }
    describe(description) {
      return description.add('same instance as ').addDescriptionOf(this[_expected]);
    }
  };
  dart.setSignature(src__matcher__core_matchers._IsSameAs, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._IsSameAs, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _limit = Symbol('_limit');
  const _compareIterables = Symbol('_compareIterables');
  const _compareSets = Symbol('_compareSets');
  const _recursiveMatch = Symbol('_recursiveMatch');
  const _match = Symbol('_match');
  src__matcher__core_matchers._DeepMatcher = class _DeepMatcher extends src__matcher__interfaces.Matcher {
    new(expected, limit) {
      if (limit === void 0) limit = 1000;
      this[_expected] = expected;
      this[_limit] = limit;
      this.count = null;
      super.new();
    }
    [_compareIterables](expected, actual, matcher, depth, location) {
      if (!core.Iterable.is(actual)) return ['is not Iterable', location];
      let expectedIterator = dart.dload(expected, 'iterator');
      let actualIterator = dart.dload(actual, 'iterator');
      for (let index = 0;; index++) {
        let expectedNext = dart.dsend(expectedIterator, 'moveNext');
        let actualNext = dart.dsend(actualIterator, 'moveNext');
        if (!dart.test(expectedNext) && !dart.test(actualNext)) return null;
        let newLocation = dart.str`${location}[${index}]`;
        if (!dart.test(expectedNext)) return JSArrayOfString().of(['longer than expected', newLocation]);
        if (!dart.test(actualNext)) return JSArrayOfString().of(['shorter than expected', newLocation]);
        let rp = dart.dcall(matcher, dart.dload(expectedIterator, 'current'), dart.dload(actualIterator, 'current'), newLocation, depth);
        if (rp != null) return core.List._check(rp);
      }
    }
    [_compareSets](expected, actual, matcher, depth, location) {
      if (!core.Iterable.is(actual)) return ['is not Iterable', location];
      actual = dart.dsend(actual, 'toSet');
      for (let expectedElement of expected) {
        if (dart.test(dart.dsend(actual, 'every', dart.fn(actualElement => dart.dcall(matcher, expectedElement, actualElement, location, depth) != null, dynamicTobool$())))) {
          return [dart.str`does not contain ${expectedElement}`, location];
        }
      }
      if (dart.test(dart.dsend(dart.dload(actual, 'length'), '>', expected.length))) {
        return ['larger than expected', location];
      } else if (dart.test(dart.dsend(dart.dload(actual, 'length'), '<', expected.length))) {
        return ['smaller than expected', location];
      } else {
        return null;
      }
    }
    [_recursiveMatch](expected, actual, location, depth) {
      if (src__matcher__interfaces.Matcher.is(expected)) {
        let matchState = dart.map();
        if (dart.test(expected.matches(actual, matchState))) return null;
        let description = new src__matcher__description.StringDescription();
        expected.describe(description);
        return JSArrayOfString().of([dart.str`does not match ${description}`, location]);
      } else {
        try {
          if (dart.equals(expected, actual)) return null;
        } catch (e) {
          return JSArrayOfString().of([dart.str`== threw "${e}"`, location]);
        }

      }
      if (dart.notNull(depth) > dart.notNull(this[_limit])) return JSArrayOfString().of(['recursion depth limit exceeded', location]);
      if (depth == 0 || dart.notNull(this[_limit]) > 1) {
        if (core.Set.is(expected)) {
          return this[_compareSets](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Iterable.is(expected)) {
          return this[_compareIterables](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Map.is(expected)) {
          if (!core.Map.is(actual)) return JSArrayOfString().of(['expected a map', location]);
          let err = dart.equals(expected[dartx.length], dart.dload(actual, 'length')) ? '' : 'has different length and ';
          for (let key of expected[dartx.keys]) {
            if (!dart.test(dart.dsend(actual, 'containsKey', key))) {
              return JSArrayOfString().of([dart.str`${err}is missing map key '${key}'`, location]);
            }
          }
          for (let key of core.Iterable._check(dart.dload(actual, 'keys'))) {
            if (!dart.test(expected[dartx.containsKey](key))) {
              return JSArrayOfString().of([dart.str`${err}has extra map key '${key}'`, location]);
            }
          }
          for (let key of expected[dartx.keys]) {
            let rp = this[_recursiveMatch](expected[dartx.get](key), dart.dindex(actual, key), dart.str`${location}['${key}']`, dart.notNull(depth) + 1);
            if (rp != null) return rp;
          }
          return null;
        }
      }
      let description = new src__matcher__description.StringDescription();
      if (dart.notNull(depth) > 0) {
        description.add('was ').addDescriptionOf(actual).add(' instead of ').addDescriptionOf(expected);
        return JSArrayOfString().of([description.toString(), location]);
      }
      return JSArrayOfString().of(["", location]);
    }
    [_match](expected, actual, matchState) {
      let rp = this[_recursiveMatch](expected, actual, '', 0);
      if (rp == null) return null;
      let reason = null;
      if (dart.test(dart.dsend(dart.dload(rp[dartx.get](0), 'length'), '>', 0))) {
        if (dart.test(dart.dsend(dart.dload(rp[dartx.get](1), 'length'), '>', 0))) {
          reason = dart.str`${rp[dartx.get](0)} at location ${rp[dartx.get](1)}`;
        } else {
          reason = rp[dartx.get](0);
        }
      } else {
        reason = '';
      }
      src__matcher__util.addStateInfo(matchState, dart.map({reason: reason}, core.String, dart.dynamic));
      return core.String._check(reason);
    }
    matches(item, matchState) {
      return this[_match](this[_expected], item, matchState) == null;
    }
    describe(description) {
      return description.addDescriptionOf(this[_expected]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      let reason = matchState[dartx.get]('reason');
      if (dart.equals(dart.dload(reason, 'length'), 0) && dart.notNull(mismatchDescription.length) > 0) {
        mismatchDescription.add('is ').addDescriptionOf(item);
      } else {
        mismatchDescription.add(core.String._check(reason));
      }
      return mismatchDescription;
    }
  };
  dart.setSignature(src__matcher__core_matchers._DeepMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._DeepMatcher, [dart.dynamic], [core.int])}),
    methods: () => ({
      [_compareIterables]: dart.definiteFunctionType(core.List, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_compareSets]: dart.definiteFunctionType(core.List, [core.Set, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_recursiveMatch]: dart.definiteFunctionType(core.List, [dart.dynamic, dart.dynamic, core.String, core.int]),
      [_match]: dart.definiteFunctionType(core.String, [dart.dynamic, dart.dynamic, core.Map]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _value$ = Symbol('_value');
  src__matcher__core_matchers._StringEqualsMatcher = class _StringEqualsMatcher extends src__matcher__interfaces.Matcher {
    new(value) {
      this[_value$] = value;
      super.new();
    }
    get showActualValue() {
      return true;
    }
    matches(item, matchState) {
      return dart.equals(this[_value$], item);
    }
    describe(description) {
      return description.addDescriptionOf(this[_value$]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'string')) {
        return mismatchDescription.addDescriptionOf(item).add('is not a string');
      } else {
        let buff = new core.StringBuffer();
        buff.write('is different.');
        let escapedItem = src__matcher__util.escape(core.String._check(item));
        let escapedValue = src__matcher__util.escape(this[_value$]);
        let minLength = dart.notNull(escapedItem[dartx.length]) < dart.notNull(escapedValue[dartx.length]) ? escapedItem[dartx.length] : escapedValue[dartx.length];
        let start = null;
        for (start = 0; dart.notNull(start) < dart.notNull(minLength); start = dart.notNull(start) + 1) {
          if (escapedValue[dartx.codeUnitAt](start) != escapedItem[dartx.codeUnitAt](start)) {
            break;
          }
        }
        if (start == minLength) {
          if (dart.notNull(escapedValue[dartx.length]) < dart.notNull(escapedItem[dartx.length])) {
            buff.write(' Both strings start the same, but the given value also' + ' has the following trailing characters: ');
            src__matcher__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedItem, escapedValue[dartx.length]);
          } else {
            buff.write(' Both strings start the same, but the given value is' + ' missing the following trailing characters: ');
            src__matcher__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedValue, escapedItem[dartx.length]);
          }
        } else {
          buff.write('\nExpected: ');
          src__matcher__core_matchers._StringEqualsMatcher._writeLeading(buff, escapedValue, start);
          src__matcher__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedValue, start);
          buff.write('\n  Actual: ');
          src__matcher__core_matchers._StringEqualsMatcher._writeLeading(buff, escapedItem, start);
          src__matcher__core_matchers._StringEqualsMatcher._writeTrailing(buff, escapedItem, start);
          buff.write('\n          ');
          for (let i = dart.notNull(start) > 10 ? 14 : start; dart.notNull(i) > 0; i = dart.notNull(i) - 1)
            buff.write(' ');
          buff.write(dart.str`^\n Differ at offset ${start}`);
        }
        return mismatchDescription.replace(buff.toString());
      }
    }
    static _writeLeading(buff, s, start) {
      if (dart.notNull(start) > 10) {
        buff.write('... ');
        buff.write(s[dartx.substring](dart.notNull(start) - 10, start));
      } else {
        buff.write(s[dartx.substring](0, start));
      }
    }
    static _writeTrailing(buff, s, start) {
      if (dart.notNull(start) + 10 > dart.notNull(s[dartx.length])) {
        buff.write(s[dartx.substring](start));
      } else {
        buff.write(s[dartx.substring](start, dart.notNull(start) + 10));
        buff.write(' ...');
      }
    }
  };
  dart.setSignature(src__matcher__core_matchers._StringEqualsMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._StringEqualsMatcher, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    }),
    statics: () => ({
      _writeLeading: dart.definiteFunctionType(dart.void, [core.StringBuffer, core.String, core.int]),
      _writeTrailing: dart.definiteFunctionType(dart.void, [core.StringBuffer, core.String, core.int])
    }),
    names: ['_writeLeading', '_writeTrailing']
  });
  src__matcher__core_matchers._HasLength = class _HasLength extends src__matcher__interfaces.Matcher {
    new(matcher) {
      if (matcher === void 0) matcher = null;
      this[_matcher] = matcher;
      super.new();
    }
    matches(item, matchState) {
      try {
        if (dart.test(dart.dsend(dart.dsend(dart.dload(item, 'length'), '*', dart.dload(item, 'length')), '>=', 0))) {
          return this[_matcher].matches(dart.dload(item, 'length'), matchState);
        }
      } catch (e) {
      }

      return false;
    }
    describe(description) {
      return description.add('an object with length of ').addDescriptionOf(this[_matcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      try {
        if (dart.test(dart.dsend(dart.dsend(dart.dload(item, 'length'), '*', dart.dload(item, 'length')), '>=', 0))) {
          return mismatchDescription.add('has length of ').addDescriptionOf(dart.dload(item, 'length'));
        }
      } catch (e) {
      }

      return mismatchDescription.add('has no length property');
    }
  };
  dart.setSignature(src__matcher__core_matchers._HasLength, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._HasLength, [], [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers._Contains = class _Contains extends src__matcher__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      if (typeof item == 'string') {
        return dart.notNull(item[dartx.indexOf](core.Pattern._check(this[_expected]))) >= 0;
      } else if (core.Iterable.is(item)) {
        if (src__matcher__interfaces.Matcher.is(this[_expected])) {
          return item[dartx.any](dart.fn(e => core.bool._check(dart.dsend(this[_expected], 'matches', e, matchState)), dynamicTobool$()));
        } else {
          return item[dartx.contains](this[_expected]);
        }
      } else if (core.Map.is(item)) {
        return item[dartx.containsKey](this[_expected]);
      }
      return false;
    }
    describe(description) {
      return description.add('contains ').addDescriptionOf(this[_expected]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (typeof item == 'string' || core.Iterable.is(item) || core.Map.is(item)) {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      } else {
        return mismatchDescription.add('is not a string, map or iterable');
      }
    }
  };
  dart.setSignature(src__matcher__core_matchers._Contains, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._Contains, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers._In = class _In extends src__matcher__interfaces.Matcher {
    new(expected) {
      this[_expected] = expected;
      super.new();
    }
    matches(item, matchState) {
      if (typeof this[_expected] == 'string') {
        return core.bool._check(dart.dsend(dart.dsend(this[_expected], 'indexOf', item), '>=', 0));
      } else if (core.Iterable.is(this[_expected])) {
        return core.bool._check(dart.dsend(this[_expected], 'any', dart.fn(e => dart.equals(e, item), dynamicTobool$())));
      } else if (core.Map.is(this[_expected])) {
        return core.bool._check(dart.dsend(this[_expected], 'containsKey', item));
      }
      return false;
    }
    describe(description) {
      return description.add('is in ').addDescriptionOf(this[_expected]);
    }
  };
  dart.setSignature(src__matcher__core_matchers._In, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._In, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__core_matchers._PredicateFunction = dart.typedef('_PredicateFunction', () => dart.functionType(core.bool, [dart.dynamic]));
  const _description = Symbol('_description');
  src__matcher__core_matchers._Predicate = class _Predicate extends src__matcher__interfaces.Matcher {
    new(matcher, description) {
      this[_matcher] = matcher;
      this[_description] = description;
      super.new();
    }
    matches(item, matchState) {
      return dart.dcall(this[_matcher], item);
    }
    describe(description) {
      return description.add(this[_description]);
    }
  };
  dart.setSignature(src__matcher__core_matchers._Predicate, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__core_matchers._Predicate, [src__matcher__core_matchers._PredicateFunction, core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__pretty_print.prettyPrint = function(object, opts) {
    let maxLineLength = opts && 'maxLineLength' in opts ? opts.maxLineLength : null;
    let maxItems = opts && 'maxItems' in opts ? opts.maxItems : null;
    function _prettyPrint(object, indent, seen, top) {
      if (src__matcher__interfaces.Matcher.is(object)) {
        let description = new src__matcher__description.StringDescription();
        object.describe(description);
        return dart.str`<${description}>`;
      }
      if (dart.test(seen.contains(object))) return "(recursive)";
      seen = seen.union(core.Set.from([object]));
      function pp(child) {
        return _prettyPrint(child, dart.notNull(indent) + 2, seen, false);
      }
      dart.fn(pp, dynamicToString());
      if (core.Iterable.is(object)) {
        let type = core.List.is(object) ? "" : dart.notNull(src__matcher__pretty_print._typeName(object)) + ":";
        let strings = object[dartx.map](core.String)(pp)[dartx.toList]();
        if (maxItems != null && dart.notNull(strings[dartx.length]) > dart.notNull(maxItems)) {
          strings[dartx.replaceRange](dart.notNull(maxItems) - 1, strings[dartx.length], JSArrayOfString().of(['...']));
        }
        let singleLine = dart.str`${type}[${strings[dartx.join](', ')}]`;
        if ((maxLineLength == null || dart.notNull(singleLine[dartx.length]) + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !dart.test(singleLine[dartx.contains]("\n"))) {
          return singleLine;
        }
        return dart.str`${type}[\n` + dart.notNull(strings[dartx.map](core.String)(dart.fn(string => dart.notNull(src__matcher__pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string), StringToString()))[dartx.join](",\n")) + "\n" + dart.notNull(src__matcher__pretty_print._indent(indent)) + "]";
      } else if (core.Map.is(object)) {
        let strings = object[dartx.keys][dartx.map](core.String)(dart.fn(key => dart.str`${pp(key)}: ${pp(object[dartx.get](key))}`, dynamicToString()))[dartx.toList]();
        if (maxItems != null && dart.notNull(strings[dartx.length]) > dart.notNull(maxItems)) {
          strings[dartx.replaceRange](dart.notNull(maxItems) - 1, strings[dartx.length], JSArrayOfString().of(['...']));
        }
        let singleLine = dart.str`{${strings[dartx.join](", ")}}`;
        if ((maxLineLength == null || dart.notNull(singleLine[dartx.length]) + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !dart.test(singleLine[dartx.contains]("\n"))) {
          return singleLine;
        }
        return "{\n" + dart.notNull(strings[dartx.map](core.String)(dart.fn(string => dart.notNull(src__matcher__pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string), StringToString()))[dartx.join](",\n")) + "\n" + dart.notNull(src__matcher__pretty_print._indent(indent)) + "}";
      } else if (typeof object == 'string') {
        let lines = object[dartx.split]("\n");
        return "'" + dart.notNull(lines[dartx.map](core.String)(src__matcher__pretty_print._escapeString)[dartx.join](dart.str`\\n'\n${src__matcher__pretty_print._indent(dart.notNull(indent) + 2)}'`)) + "'";
      } else {
        let value = dart.toString(object)[dartx.replaceAll]("\n", dart.notNull(src__matcher__pretty_print._indent(indent)) + "\n");
        let defaultToString = value[dartx.startsWith]("Instance of ");
        if (dart.test(top)) value = dart.str`<${value}>`;
        if (typeof object == 'number' || typeof object == 'boolean' || core.Function.is(object) || object == null || dart.test(defaultToString)) {
          return value;
        } else {
          return dart.str`${src__matcher__pretty_print._typeName(object)}:${value}`;
        }
      }
    }
    dart.fn(_prettyPrint, dynamicAndintAndSet__ToString());
    return _prettyPrint(object, 0, core.Set.new(), true);
  };
  dart.fn(src__matcher__pretty_print.prettyPrint, dynamic__ToString());
  src__matcher__pretty_print._indent = function(length) {
    return ListOfString().filled(length, ' ')[dartx.join]('');
  };
  dart.fn(src__matcher__pretty_print._indent, intToString());
  src__matcher__pretty_print._typeName = function(x) {
    try {
      if (x == null) return "null";
      let type = dart.toString(dart.runtimeType(x));
      return dart.test(type[dartx.startsWith]("_")) ? "?" : type;
    } catch (e) {
      return "?";
    }

  };
  dart.fn(src__matcher__pretty_print._typeName, dynamicToString());
  src__matcher__pretty_print._escapeString = function(source) {
    return src__matcher__util.escape(source)[dartx.replaceAll]("'", "\\'");
  };
  dart.fn(src__matcher__pretty_print._escapeString, StringToString());
  src__matcher__util._Predicate = dart.typedef('_Predicate', () => dart.functionType(core.bool, [dart.dynamic]));
  src__matcher__util._escapeMap = dart.const(dart.map({'\n': '\\n', '\r': '\\r', '\f': '\\f', '\b': '\\b', '\t': '\\t', '\v': '\\v', '': '\\x7F'}, core.String, core.String));
  dart.defineLazy(src__matcher__util, {
    get _escapeRegExp() {
      return core.RegExp.new(dart.str`[\\x00-\\x07\\x0E-\\x1F${src__matcher__util._escapeMap[dartx.keys][dartx.map](core.String)(src__matcher__util._getHexLiteral)[dartx.join]()}]`);
    }
  });
  src__matcher__util._getHexLiteral = function(input) {
    let rune = input[dartx.runes].single;
    return '\\x' + dart.notNull(rune[dartx.toRadixString](16)[dartx.toUpperCase]()[dartx.padLeft](2, '0'));
  };
  dart.fn(src__matcher__util._getHexLiteral, StringToString());
  src__matcher__expect._assertFailureHandler = null;
  src__matcher__expect._assertErrorFormatter = null;
  src__matcher__expect._defaultErrorFormatter = function(actual, matcher, reason, matchState, verbose) {
    let description = new src__matcher__description.StringDescription();
    description.add('Expected: ').addDescriptionOf(matcher).add('\n');
    description.add('  Actual: ').addDescriptionOf(actual).add('\n');
    let mismatchDescription = new src__matcher__description.StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);
    if (dart.notNull(mismatchDescription.length) > 0) {
      description.add(dart.str`   Which: ${mismatchDescription}\n`);
    }
    if (reason != null) {
      description.add(reason).add('\n');
    }
    return description.toString();
  };
  dart.fn(src__matcher__expect._defaultErrorFormatter, dynamicAndMatcherAndString__ToString());
  const _matcher$1 = Symbol('_matcher');
  src__matcher__iterable_matchers._IterableMatcher = class _IterableMatcher extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.addDescriptionOf(item).add(' not an Iterable');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._IterableMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._IterableMatcher, [])})
  });
  src__matcher__iterable_matchers._EveryElement = class _EveryElement extends src__matcher__iterable_matchers._IterableMatcher {
    new(matcher) {
      this[_matcher$1] = matcher;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Iterable.is(item)) {
        return false;
      }
      let i = 0;
      for (let element of core.Iterable._check(item)) {
        if (!dart.test(this[_matcher$1].matches(element, matchState))) {
          src__matcher__util.addStateInfo(matchState, dart.map({index: i, element: element}, core.String, dart.dynamic));
          return false;
        }
        ++i;
      }
      return true;
    }
    describe(description) {
      return description.add('every element(').addDescriptionOf(this[_matcher$1]).add(')');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (matchState[dartx.get]('index') != null) {
        let index = matchState[dartx.get]('index');
        let element = matchState[dartx.get]('element');
        mismatchDescription.add('has value ').addDescriptionOf(element).add(' which ');
        let subDescription = new src__matcher__description.StringDescription();
        this[_matcher$1].describeMismatch(element, subDescription, core.Map._check(matchState[dartx.get]('state')), verbose);
        if (dart.notNull(subDescription.length) > 0) {
          mismatchDescription.add(subDescription.toString());
        } else {
          mismatchDescription.add("doesn't match ");
          this[_matcher$1].describe(mismatchDescription);
        }
        mismatchDescription.add(dart.str` at index ${index}`);
        return mismatchDescription;
      }
      return super.describeMismatch(item, mismatchDescription, matchState, verbose);
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._EveryElement, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._EveryElement, [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__iterable_matchers._AnyElement = class _AnyElement extends src__matcher__iterable_matchers._IterableMatcher {
    new(matcher) {
      this[_matcher$1] = matcher;
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dsend(item, 'any', dart.fn(e => this[_matcher$1].matches(e, matchState), dynamicTobool$())));
    }
    describe(description) {
      return description.add('some element ').addDescriptionOf(this[_matcher$1]);
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._AnyElement, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._AnyElement, [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _expected$ = Symbol('_expected');
  src__matcher__iterable_matchers._OrderedEquals = class _OrderedEquals extends src__matcher__interfaces.Matcher {
    new(expected) {
      this[_expected$] = expected;
      this[_matcher$1] = null;
      super.new();
      this[_matcher$1] = src__matcher__core_matchers.equals(this[_expected$], 1);
    }
    matches(item, matchState) {
      return core.Iterable.is(item) && dart.test(this[_matcher$1].matches(item, matchState));
    }
    describe(description) {
      return description.add('equals ').addDescriptionOf(this[_expected$]).add(' ordered');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.add('is not an Iterable');
      } else {
        return this[_matcher$1].describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._OrderedEquals, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._OrderedEquals, [core.Iterable])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _expectedValues = Symbol('_expectedValues');
  const _test = Symbol('_test');
  src__matcher__iterable_matchers._UnorderedMatches = class _UnorderedMatches extends src__matcher__interfaces.Matcher {
    new(expected) {
      this[_expected$] = expected[dartx.map](src__matcher__interfaces.Matcher)(src__matcher__util.wrapMatcher)[dartx.toList]();
      super.new();
    }
    [_test](item) {
      if (!core.Iterable.is(item)) return 'not iterable';
      item = dart.dsend(item, 'toList');
      if (dart.notNull(this[_expected$][dartx.length]) > dart.notNull(core.num._check(dart.dload(item, 'length')))) {
        return dart.str`has too few elements (${dart.dload(item, 'length')} < ${this[_expected$][dartx.length]})`;
      } else if (dart.notNull(this[_expected$][dartx.length]) < dart.notNull(core.num._check(dart.dload(item, 'length')))) {
        return dart.str`has too many elements (${dart.dload(item, 'length')} > ${this[_expected$][dartx.length]})`;
      }
      let matched = ListOfbool().filled(core.int._check(dart.dload(item, 'length')), false);
      let expectedPosition = 0;
      for (let expectedMatcher of this[_expected$]) {
        let actualPosition = 0;
        let gotMatch = false;
        for (let actualElement of core.Iterable._check(item)) {
          if (!dart.test(matched[dartx.get](actualPosition))) {
            if (dart.test(expectedMatcher.matches(actualElement, dart.map()))) {
              matched[dartx.set](actualPosition, gotMatch = true);
              break;
            }
          }
          ++actualPosition;
        }
        if (!gotMatch) {
          return dart.toString(new src__matcher__description.StringDescription().add('has no match for ').addDescriptionOf(expectedMatcher).add(dart.str` at index ${expectedPosition}`));
        }
        ++expectedPosition;
      }
      return null;
    }
    matches(item, mismatchState) {
      return this[_test](item) == null;
    }
    describe(description) {
      return description.add('matches ').addAll('[', ', ', ']', this[_expected$]).add(' unordered');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      return mismatchDescription.add(this[_test](item));
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._UnorderedMatches, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._UnorderedMatches, [core.Iterable])}),
    methods: () => ({
      [_test]: dart.definiteFunctionType(core.String, [dart.dynamic]),
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__iterable_matchers._UnorderedEquals = class _UnorderedEquals extends src__matcher__iterable_matchers._UnorderedMatches {
    new(expected) {
      this[_expectedValues] = expected[dartx.toList]();
      super.new(expected[dartx.map](src__matcher__interfaces.Matcher)(src__matcher__core_matchers.equals));
    }
    describe(description) {
      return description.add('equals ').addDescriptionOf(this[_expectedValues]).add(' unordered');
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._UnorderedEquals, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._UnorderedEquals, [core.Iterable])})
  });
  src__matcher__iterable_matchers._Comparator = dart.typedef('_Comparator', () => dart.functionType(core.bool, [dart.dynamic, dart.dynamic]));
  const _comparator = Symbol('_comparator');
  const _description$ = Symbol('_description');
  src__matcher__iterable_matchers._PairwiseCompare = class _PairwiseCompare extends src__matcher__iterable_matchers._IterableMatcher {
    new(expected, comparator, description) {
      this[_expected$] = expected;
      this[_comparator] = comparator;
      this[_description$] = description;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Iterable.is(item)) return false;
      if (!dart.equals(dart.dload(item, 'length'), this[_expected$][dartx.length])) return false;
      let iterator = dart.dload(item, 'iterator');
      let i = 0;
      for (let e of this[_expected$]) {
        dart.dsend(iterator, 'moveNext');
        if (!dart.test(dart.dcall(this[_comparator], e, dart.dload(iterator, 'current')))) {
          src__matcher__util.addStateInfo(matchState, dart.map({index: i, expected: e, actual: dart.dload(iterator, 'current')}, core.String, dart.dynamic));
          return false;
        }
        i++;
      }
      return true;
    }
    describe(description) {
      return description.add(dart.str`pairwise ${this[_description$]} `).addDescriptionOf(this[_expected$]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!core.Iterable.is(item)) {
        return mismatchDescription.add('is not an Iterable');
      } else if (!dart.equals(dart.dload(item, 'length'), this[_expected$][dartx.length])) {
        return mismatchDescription.add(dart.str`has length ${dart.dload(item, 'length')} instead of ${this[_expected$][dartx.length]}`);
      } else {
        return mismatchDescription.add('has ').addDescriptionOf(matchState[dartx.get]("actual")).add(dart.str` which is not ${this[_description$]} `).addDescriptionOf(matchState[dartx.get]("expected")).add(dart.str` at index ${matchState[dartx.get]("index")}`);
      }
    }
  };
  dart.setSignature(src__matcher__iterable_matchers._PairwiseCompare, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__iterable_matchers._PairwiseCompare, [core.Iterable, src__matcher__iterable_matchers._Comparator, core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _value$0 = Symbol('_value');
  src__matcher__map_matchers._ContainsValue = class _ContainsValue extends src__matcher__interfaces.Matcher {
    new(value) {
      this[_value$0] = value;
      super.new();
    }
    matches(item, matchState) {
      return core.bool._check(dart.dsend(item, 'containsValue', this[_value$0]));
    }
    describe(description) {
      return description.add('contains value ').addDescriptionOf(this[_value$0]);
    }
  };
  dart.setSignature(src__matcher__map_matchers._ContainsValue, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__map_matchers._ContainsValue, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _key = Symbol('_key');
  const _valueMatcher = Symbol('_valueMatcher');
  src__matcher__map_matchers._ContainsMapping = class _ContainsMapping extends src__matcher__interfaces.Matcher {
    new(key, valueMatcher) {
      this[_key] = key;
      this[_valueMatcher] = valueMatcher;
      super.new();
    }
    matches(item, matchState) {
      return dart.test(dart.dsend(item, 'containsKey', this[_key])) && dart.test(this[_valueMatcher].matches(dart.dindex(item, this[_key]), matchState));
    }
    describe(description) {
      return description.add('contains pair ').addDescriptionOf(this[_key]).add(' => ').addDescriptionOf(this[_valueMatcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!dart.test(dart.dsend(item, 'containsKey', this[_key]))) {
        return mismatchDescription.add(" doesn't contain key ").addDescriptionOf(this[_key]);
      } else {
        mismatchDescription.add(' contains key ').addDescriptionOf(this[_key]).add(' but with value ');
        this[_valueMatcher].describeMismatch(dart.dindex(item, this[_key]), mismatchDescription, matchState, verbose);
        return mismatchDescription;
      }
    }
  };
  dart.setSignature(src__matcher__map_matchers._ContainsMapping, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__map_matchers._ContainsMapping, [dart.dynamic, src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__numeric_matchers._isNumeric = function(value) {
    return typeof value == 'number';
  };
  dart.fn(src__matcher__numeric_matchers._isNumeric, dynamicTobool$());
  const _delta = Symbol('_delta');
  src__matcher__numeric_matchers._IsCloseTo = class _IsCloseTo extends src__matcher__interfaces.Matcher {
    new(value, delta) {
      this[_value] = value;
      this[_delta] = delta;
      super.new();
    }
    matches(item, matchState) {
      if (!dart.test(src__matcher__numeric_matchers._isNumeric(item))) {
        return false;
      }
      let diff = dart.dsend(item, '-', this[_value]);
      if (dart.test(dart.dsend(diff, '<', 0))) diff = dart.dsend(diff, 'unary-');
      return core.bool._check(dart.dsend(diff, '<=', this[_delta]));
    }
    describe(description) {
      return description.add('a numeric value within ').addDescriptionOf(this[_delta]).add(' of ').addDescriptionOf(this[_value]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'number')) {
        return mismatchDescription.add(' not numeric');
      } else {
        let diff = dart.dsend(item, '-', this[_value]);
        if (dart.test(dart.dsend(diff, '<', 0))) diff = dart.dsend(diff, 'unary-');
        return mismatchDescription.add(' differs by ').addDescriptionOf(diff);
      }
    }
  };
  dart.setSignature(src__matcher__numeric_matchers._IsCloseTo, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__numeric_matchers._IsCloseTo, [core.num, core.num])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _low = Symbol('_low');
  const _high = Symbol('_high');
  const _lowMatchValue = Symbol('_lowMatchValue');
  const _highMatchValue = Symbol('_highMatchValue');
  src__matcher__numeric_matchers._InRange = class _InRange extends src__matcher__interfaces.Matcher {
    new(low, high, lowMatchValue, highMatchValue) {
      this[_low] = low;
      this[_high] = high;
      this[_lowMatchValue] = lowMatchValue;
      this[_highMatchValue] = highMatchValue;
      super.new();
    }
    matches(value, matchState) {
      if (!(typeof value == 'number')) {
        return false;
      }
      if (dart.test(dart.dsend(value, '<', this[_low])) || dart.test(dart.dsend(value, '>', this[_high]))) {
        return false;
      }
      if (dart.equals(value, this[_low])) {
        return this[_lowMatchValue];
      }
      if (dart.equals(value, this[_high])) {
        return this[_highMatchValue];
      }
      return true;
    }
    describe(description) {
      return description.add("be in range from " + dart.str`${this[_low]} (${dart.test(this[_lowMatchValue]) ? 'inclusive' : 'exclusive'}) to ` + dart.str`${this[_high]} (${dart.test(this[_highMatchValue]) ? 'inclusive' : 'exclusive'})`);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'number')) {
        return mismatchDescription.addDescriptionOf(item).add(' not numeric');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__matcher__numeric_matchers._InRange, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__numeric_matchers._InRange, [core.num, core.num, core.bool, core.bool])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _matcher$2 = Symbol('_matcher');
  src__matcher__operator_matchers._IsNot = class _IsNot extends src__matcher__interfaces.Matcher {
    new(matcher) {
      this[_matcher$2] = matcher;
      super.new();
    }
    matches(item, matchState) {
      return !dart.test(this[_matcher$2].matches(item, matchState));
    }
    describe(description) {
      return description.add('not ').addDescriptionOf(this[_matcher$2]);
    }
  };
  dart.setSignature(src__matcher__operator_matchers._IsNot, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__operator_matchers._IsNot, [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _matchers = Symbol('_matchers');
  src__matcher__operator_matchers._AllOf = class _AllOf extends src__matcher__interfaces.Matcher {
    new(matchers) {
      this[_matchers] = matchers;
      super.new();
    }
    matches(item, matchState) {
      for (let matcher of this[_matchers]) {
        if (!dart.test(matcher.matches(item, matchState))) {
          src__matcher__util.addStateInfo(matchState, dart.map({matcher: matcher}, core.String, src__matcher__interfaces.Matcher));
          return false;
        }
      }
      return true;
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      let matcher = matchState[dartx.get]('matcher');
      dart.dsend(matcher, 'describeMismatch', item, mismatchDescription, matchState[dartx.get]('state'), verbose);
      return mismatchDescription;
    }
    describe(description) {
      return description.addAll('(', ' and ', ')', this[_matchers]);
    }
  };
  dart.setSignature(src__matcher__operator_matchers._AllOf, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__operator_matchers._AllOf, [core.List$(src__matcher__interfaces.Matcher)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__operator_matchers._AnyOf = class _AnyOf extends src__matcher__interfaces.Matcher {
    new(matchers) {
      this[_matchers] = matchers;
      super.new();
    }
    matches(item, matchState) {
      for (let matcher of this[_matchers]) {
        if (dart.test(matcher.matches(item, matchState))) {
          return true;
        }
      }
      return false;
    }
    describe(description) {
      return description.addAll('(', ' or ', ')', this[_matchers]);
    }
  };
  dart.setSignature(src__matcher__operator_matchers._AnyOf, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__operator_matchers._AnyOf, [core.List$(src__matcher__interfaces.Matcher)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__operator_matchers._wrapArgs = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    let args = null;
    if (core.List.is(arg0)) {
      if (arg1 != null || arg2 != null || arg3 != null || arg4 != null || arg5 != null || arg6 != null) {
        dart.throw(new core.ArgumentError('If arg0 is a List, all other arguments must be' + ' null.'));
      }
      args = arg0;
    } else {
      args = [arg0, arg1, arg2, arg3, arg4, arg5, arg6][dartx.where](dart.fn(e => e != null, dynamicTobool$()));
    }
    return args[dartx.map](src__matcher__interfaces.Matcher)(dart.fn(e => src__matcher__util.wrapMatcher(e), dynamicToMatcher()))[dartx.toList]();
  };
  dart.fn(src__matcher__operator_matchers._wrapArgs, dynamicAnddynamicAnddynamic__ToListOfMatcher());
  const _matcher$3 = Symbol('_matcher');
  src__matcher__prints_matcher._Prints = class _Prints extends src__matcher__interfaces.Matcher {
    new(matcher) {
      this[_matcher$3] = matcher;
      super.new();
    }
    matches(item, matchState) {
      if (!core.Function.is(item)) return false;
      let buffer = new core.StringBuffer();
      let result = async.runZoned(dart.dynamic)(VoidTodynamic()._check(item), {zoneSpecification: async.ZoneSpecification.new({print: dart.fn((_, __, ____, line) => {
            buffer.writeln(line);
          }, ZoneAndZoneDelegateAndZone__Tovoid())})});
      if (!async.Future.is(result)) {
        let actual = buffer.toString();
        matchState[dartx.set]('prints.actual', actual);
        return this[_matcher$3].matches(actual, matchState);
      }
      return src__matcher__future_matchers.completes.matches(dart.dsend(result, 'then', dart.dcall(src__matcher__expect.wrapAsync, dart.fn(_ => {
        src__matcher__expect.expect(buffer.toString(), this[_matcher$3]);
      }, dynamicTodynamic()), 'prints')), matchState);
    }
    describe(description) {
      return description.add('prints ').addDescriptionOf(this[_matcher$3]);
    }
    describeMismatch(item, description, matchState, verbose) {
      let actual = matchState[dartx.remove]('prints.actual');
      if (actual == null) return description;
      if (dart.test(dart.dload(actual, 'isEmpty'))) return description.add("printed nothing.");
      description.add('printed ').addDescriptionOf(actual);
      let innerMismatch = dart.toString(this[_matcher$3].describeMismatch(actual, new src__matcher__description.StringDescription(), matchState, verbose));
      if (dart.test(innerMismatch[dartx.isNotEmpty])) {
        description.add('\n   Which: ').add(dart.toString(innerMismatch));
      }
      return description;
    }
  };
  dart.setSignature(src__matcher__prints_matcher._Prints, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__prints_matcher._Prints, [src__matcher__interfaces.Matcher])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _value$1 = Symbol('_value');
  const _matchValue = Symbol('_matchValue');
  src__matcher__string_matchers._StringMatcher = class _StringMatcher extends src__matcher__interfaces.Matcher {
    new() {
      super.new();
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (!(typeof item == 'string')) {
        return mismatchDescription.addDescriptionOf(item).add(' not a string');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__matcher__string_matchers._StringMatcher, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._StringMatcher, [])})
  });
  src__matcher__string_matchers._IsEqualIgnoringCase = class _IsEqualIgnoringCase extends src__matcher__string_matchers._StringMatcher {
    new(value) {
      this[_value$1] = value;
      this[_matchValue] = value[dartx.toLowerCase]();
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && this[_matchValue] == item[dartx.toLowerCase]();
    }
    describe(description) {
      return description.addDescriptionOf(this[_value$1]).add(' ignoring case');
    }
  };
  dart.setSignature(src__matcher__string_matchers._IsEqualIgnoringCase, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._IsEqualIgnoringCase, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__string_matchers._IsEqualIgnoringWhitespace = class _IsEqualIgnoringWhitespace extends src__matcher__string_matchers._StringMatcher {
    new(value) {
      this[_value$1] = value;
      this[_matchValue] = src__matcher__string_matchers.collapseWhitespace(value);
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && this[_matchValue] == src__matcher__string_matchers.collapseWhitespace(item);
    }
    describe(description) {
      return description.addDescriptionOf(this[_matchValue]).add(' ignoring whitespace');
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (typeof item == 'string') {
        return mismatchDescription.add('is ').addDescriptionOf(src__matcher__string_matchers.collapseWhitespace(item)).add(' with whitespace compressed');
      } else {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      }
    }
  };
  dart.setSignature(src__matcher__string_matchers._IsEqualIgnoringWhitespace, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._IsEqualIgnoringWhitespace, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _prefix = Symbol('_prefix');
  src__matcher__string_matchers._StringStartsWith = class _StringStartsWith extends src__matcher__string_matchers._StringMatcher {
    new(prefix) {
      this[_prefix] = prefix;
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && dart.test(item[dartx.startsWith](this[_prefix]));
    }
    describe(description) {
      return description.add('a string starting with ').addDescriptionOf(this[_prefix]);
    }
  };
  dart.setSignature(src__matcher__string_matchers._StringStartsWith, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._StringStartsWith, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _suffix = Symbol('_suffix');
  src__matcher__string_matchers._StringEndsWith = class _StringEndsWith extends src__matcher__string_matchers._StringMatcher {
    new(suffix) {
      this[_suffix] = suffix;
      super.new();
    }
    matches(item, matchState) {
      return typeof item == 'string' && dart.test(item[dartx.endsWith](this[_suffix]));
    }
    describe(description) {
      return description.add('a string ending with ').addDescriptionOf(this[_suffix]);
    }
  };
  dart.setSignature(src__matcher__string_matchers._StringEndsWith, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._StringEndsWith, [core.String])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _substrings = Symbol('_substrings');
  src__matcher__string_matchers._StringContainsInOrder = class _StringContainsInOrder extends src__matcher__string_matchers._StringMatcher {
    new(substrings) {
      this[_substrings] = substrings;
      super.new();
    }
    matches(item, matchState) {
      if (!(typeof item == 'string')) {
        return false;
      }
      let from_index = 0;
      for (let s of this[_substrings]) {
        from_index = core.int._check(dart.dsend(item, 'indexOf', s, from_index));
        if (dart.notNull(from_index) < 0) return false;
      }
      return true;
    }
    describe(description) {
      return description.addAll('a string containing ', ', ', ' in order', this[_substrings]);
    }
  };
  dart.setSignature(src__matcher__string_matchers._StringContainsInOrder, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._StringContainsInOrder, [core.List$(core.String)])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  const _regexp = Symbol('_regexp');
  src__matcher__string_matchers._MatchesRegExp = class _MatchesRegExp extends src__matcher__string_matchers._StringMatcher {
    new(re) {
      this[_regexp] = null;
      super.new();
      if (typeof re == 'string') {
        this[_regexp] = core.RegExp.new(re);
      } else if (core.RegExp.is(re)) {
        this[_regexp] = re;
      } else {
        dart.throw(new core.ArgumentError('matches requires a regexp or string'));
      }
    }
    matches(item, matchState) {
      return typeof item == 'string' ? this[_regexp].hasMatch(item) : false;
    }
    describe(description) {
      return description.add(dart.str`match '${this[_regexp].pattern}'`);
    }
  };
  dart.setSignature(src__matcher__string_matchers._MatchesRegExp, {
    constructors: () => ({new: dart.definiteFunctionType(src__matcher__string_matchers._MatchesRegExp, [dart.dynamic])}),
    methods: () => ({
      matches: dart.definiteFunctionType(core.bool, [dart.dynamic, core.Map]),
      describe: dart.definiteFunctionType(src__matcher__interfaces.Description, [src__matcher__interfaces.Description])
    })
  });
  src__matcher__string_matchers._isWhitespace = function(ch) {
    return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
  };
  dart.fn(src__matcher__string_matchers._isWhitespace, StringTobool());
  const _startTime = Symbol('_startTime');
  const _runningTime = Symbol('_runningTime');
  const _testFunction = Symbol('_testFunction');
  const _setUp = Symbol('_setUp');
  const _tearDown = Symbol('_tearDown');
  const _testComplete = Symbol('_testComplete');
  const _errorHandler = Symbol('_errorHandler');
  let const$1;
  const _setResult = Symbol('_setResult');
  const _complete = Symbol('_complete');
  src__internal_test_case.InternalTestCase = class InternalTestCase extends core.Object {
    get passed() {
      return this.result == unittest.PASS;
    }
    get startTime() {
      return this[_startTime];
    }
    get runningTime() {
      return this[_runningTime];
    }
    get isComplete() {
      return !dart.test(this.enabled) || this.result != null;
    }
    new(id, description, testFunction) {
      this.id = id;
      this.description = description;
      this[_testFunction] = testFunction;
      this.currentGroup = src__test_environment.environment.currentContext.fullName;
      this[_setUp] = src__test_environment.environment.currentContext.testSetUp;
      this[_tearDown] = src__test_environment.environment.currentContext.testTearDown;
      this.callbackFunctionsOutstanding = 0;
      this.message = '';
      this.result = null;
      this.stackTrace = null;
      this[_startTime] = null;
      this[_runningTime] = null;
      this.enabled = true;
      this[_testComplete] = null;
    }
    [_errorHandler](stage) {
      return dart.fn((e, stack) => {
        if (stack == null && core.Error.is(e)) {
          stack = e.stackTrace;
        }
        if (this.result == null || this.result == unittest.PASS) {
          if (src__matcher__expect.TestFailure.is(e)) {
            this.fail(dart.str`${e}`, core.StackTrace._check(stack));
          } else {
            this.error(dart.str`${stage} failed: Caught ${e}`, core.StackTrace._check(stack));
          }
        }
      }, dynamicAnddynamicTodynamic());
    }
    run() {
      if (!dart.test(this.enabled)) return async.Future.value();
      this.result = this.stackTrace = null;
      this.message = '';
      return async.Future.value().then(dart.dynamic)(dart.fn(_ => {
        if (this[_setUp] != null) return dart.dcall(this[_setUp]);
      }, dynamicTodynamic())).catchError(this[_errorHandler]('Setup')).then(async.Future)(dart.fn(_ => {
        if (this.result != null) return async.Future.value();
        src__test_environment.config.onTestStart(this);
        this[_startTime] = new core.DateTime.now();
        this[_runningTime] = null;
        this.callbackFunctionsOutstanding = dart.notNull(this.callbackFunctionsOutstanding) + 1;
        let testReturn = this[_testFunction]();
        if (async.Future.is(testReturn)) {
          this.callbackFunctionsOutstanding = dart.notNull(this.callbackFunctionsOutstanding) + 1;
          testReturn.catchError(this[_errorHandler]('Test')).whenComplete(dart.bind(this, 'markCallbackComplete'));
        }
      }, dynamicToFuture())).catchError(this[_errorHandler]('Test')).then(dart.dynamic)(dart.fn(_ => {
        this.markCallbackComplete();
        if (this.result == null) {
          this[_testComplete] = async.Completer.new();
          return this[_testComplete].future.whenComplete(dart.fn(() => {
            if (this[_tearDown] != null) {
              return dart.dcall(this[_tearDown]);
            }
          }, VoidTodynamic$())).catchError(this[_errorHandler]('Teardown'));
        } else if (this[_tearDown] != null) {
          return dart.dcall(this[_tearDown]);
        }
      }, dynamicTodynamic())).catchError(this[_errorHandler]('Teardown')).whenComplete(dart.fn(() => {
        this[_setUp] = null;
        this[_tearDown] = null;
        this[_testFunction] = null;
      }, VoidTodynamic$()));
    }
    [_complete](testResult, messageText, stack) {
      if (messageText === void 0) messageText = '';
      if (stack === void 0) stack = null;
      if (this.runningTime == null) {
        if (this.startTime != null) {
          this[_runningTime] = new core.DateTime.now().difference(this.startTime);
        } else {
          this[_runningTime] = const$1 || (const$1 = dart.const(new core.Duration({seconds: 0})));
        }
      }
      this[_setResult](testResult, messageText, stack);
      if (this[_testComplete] != null) {
        let t = this[_testComplete];
        this[_testComplete] = null;
        t.complete(this);
      }
    }
    [_setResult](testResult, messageText, stack) {
      this.message = messageText;
      this.stackTrace = src__utils.getTrace(stack, unittest.formatStacks, unittest.filterStacks);
      if (this.stackTrace == null) this.stackTrace = stack;
      if (this.result == null) {
        this.result = testResult;
        src__test_environment.config.onTestResult(this);
      } else {
        this.result = testResult;
        src__test_environment.config.onTestResultChanged(this);
      }
    }
    pass() {
      this[_complete](unittest.PASS);
    }
    registerException(error, stackTrace) {
      if (stackTrace === void 0) stackTrace = null;
      let message = src__matcher__expect.TestFailure.is(error) ? error.message : dart.str`Caught ${error}`;
      if (this.result == null) {
        this.fail(message, stackTrace);
      } else {
        this.error(message, stackTrace);
      }
    }
    fail(messageText, stack) {
      if (stack === void 0) stack = null;
      if (this.result != null) {
        let newMessage = this.result == unittest.PASS ? dart.str`Test failed after initially passing: ${messageText}` : dart.str`Test failed more than once: ${messageText}`;
        this[_complete](unittest.ERROR, newMessage, stack);
      } else {
        this[_complete](unittest.FAIL, messageText, stack);
      }
    }
    error(messageText, stack) {
      if (stack === void 0) stack = null;
      this[_complete](unittest.ERROR, messageText, stack);
    }
    markCallbackComplete() {
      this.callbackFunctionsOutstanding = dart.notNull(this.callbackFunctionsOutstanding) - 1;
      if (this.callbackFunctionsOutstanding == 0 && !dart.test(this.isComplete)) this.pass();
    }
    toString() {
      return this.result != null ? dart.str`${this.description}: ${this.result}` : this.description;
    }
  };
  src__internal_test_case.InternalTestCase[dart.implements] = () => [src__test_case.TestCase];
  dart.setSignature(src__internal_test_case.InternalTestCase, {
    constructors: () => ({new: dart.definiteFunctionType(src__internal_test_case.InternalTestCase, [core.int, core.String, unittest.TestFunction])}),
    methods: () => ({
      [_errorHandler]: dart.definiteFunctionType(core.Function, [core.String]),
      run: dart.definiteFunctionType(async.Future, []),
      [_complete]: dart.definiteFunctionType(dart.void, [core.String], [core.String, core.StackTrace]),
      [_setResult]: dart.definiteFunctionType(dart.void, [core.String, core.String, core.StackTrace]),
      pass: dart.definiteFunctionType(dart.void, []),
      registerException: dart.definiteFunctionType(dart.void, [dart.dynamic], [core.StackTrace]),
      fail: dart.definiteFunctionType(dart.void, [core.String], [core.StackTrace]),
      error: dart.definiteFunctionType(dart.void, [core.String], [core.StackTrace]),
      markCallbackComplete: dart.definiteFunctionType(dart.void, [])
    })
  });
  dart.defineLazy(src__test_environment, {
    get _defaultEnvironment() {
      return new src__test_environment.TestEnvironment();
    }
  });
  let const$2;
  dart.copyProperties(src__test_environment, {
    get environment() {
      let environment = async.Zone.current.get(const$2 || (const$2 = dart.const(core.Symbol.new('unittest.environment'))));
      return src__test_environment.TestEnvironment._check(environment == null ? src__test_environment._defaultEnvironment : environment);
    }
  });
  dart.copyProperties(src__test_environment, {
    get config() {
      return src__test_environment.environment.config;
    }
  });
  src__test_environment.TestEnvironment = class TestEnvironment extends core.Object {
    new() {
      this.rootContext = new src__group_context.GroupContext.root();
      this.lastBreath = new core.DateTime.now().millisecondsSinceEpoch;
      this.testCases = ListOfInternalTestCase().new();
      this.config = null;
      this.currentContext = null;
      this.currentTestCaseIndex = -1;
      this.initialized = false;
      this.soloNestingLevel = 0;
      this.soloTestSeen = false;
      this.uncaughtErrorMessage = null;
      this.currentContext = this.rootContext;
    }
  };
  dart.setSignature(src__test_environment.TestEnvironment, {
    constructors: () => ({new: dart.definiteFunctionType(src__test_environment.TestEnvironment, [])})
  });
  const _testSetUp = Symbol('_testSetUp');
  const _testTearDown = Symbol('_testTearDown');
  const _name$ = Symbol('_name');
  src__group_context.GroupContext = class GroupContext extends core.Object {
    get isRoot() {
      return this.parent == null;
    }
    get testSetUp() {
      return this[_testSetUp];
    }
    set testSetUp(setUp) {
      if (this.parent == null || this.parent.testSetUp == null) {
        this[_testSetUp] = setUp;
        return;
      }
      this[_testSetUp] = dart.fn(() => {
        let f = dart.dsend(this.parent, 'testSetUp');
        if (async.Future.is(f)) {
          return f.then(dart.dynamic)(dart.fn(_ => dart.dcall(setUp), dynamicTodynamic()));
        } else {
          return dart.dcall(setUp);
        }
      }, VoidTodynamic$());
    }
    get testTearDown() {
      return this[_testTearDown];
    }
    set testTearDown(tearDown) {
      if (this.parent == null || this.parent.testTearDown == null) {
        this[_testTearDown] = tearDown;
        return;
      }
      this[_testTearDown] = dart.fn(() => {
        let f = dart.dcall(tearDown);
        if (async.Future.is(f)) {
          return f.then(dart.dynamic)(dart.fn(_ => dart.dsend(this.parent, 'testTearDown'), dynamicTodynamic()));
        } else {
          return dart.dsend(this.parent, 'testTearDown');
        }
      }, VoidTodynamic$());
    }
    get fullName() {
      return dart.test(this.isRoot) || dart.test(this.parent.isRoot) ? this[_name$] : dart.str`${this.parent.fullName}${unittest.groupSep}${this[_name$]}`;
    }
    root() {
      this.parent = null;
      this[_name$] = '';
      this[_testSetUp] = null;
      this[_testTearDown] = null;
    }
    new(parent, name) {
      this.parent = parent;
      this[_name$] = name;
      this[_testSetUp] = null;
      this[_testTearDown] = null;
      this[_testSetUp] = this.parent.testSetUp;
      this[_testTearDown] = this.parent.testTearDown;
    }
  };
  dart.defineNamedConstructor(src__group_context.GroupContext, 'root');
  dart.setSignature(src__group_context.GroupContext, {
    constructors: () => ({
      root: dart.definiteFunctionType(src__group_context.GroupContext, []),
      new: dart.definiteFunctionType(src__group_context.GroupContext, [src__group_context.GroupContext, core.String])
    })
  });
  src__utils.indent = function(str) {
    return str[dartx.replaceAll](core.RegExp.new("^", {multiLine: true}), "  ");
  };
  dart.fn(src__utils.indent, StringToString());
  src__utils.Pair$ = dart.generic((E, F) => {
    class Pair extends core.Object {
      new(first, last) {
        this.first = first;
        this.last = last;
      }
      toString() {
        return dart.str`(${this.first}, ${this.last})`;
      }
      ['=='](other) {
        if (!src__utils.Pair.is(other)) return false;
        return dart.equals(dart.dload(other, 'first'), this.first) && dart.equals(dart.dload(other, 'last'), this.last);
      }
      get hashCode() {
        return (dart.notNull(dart.hashCode(this.first)) ^ dart.notNull(dart.hashCode(this.last))) >>> 0;
      }
    }
    dart.addTypeTests(Pair);
    dart.setSignature(Pair, {
      constructors: () => ({new: dart.definiteFunctionType(src__utils.Pair$(E, F), [E, F])})
    });
    return Pair;
  });
  src__utils.Pair = Pair();
  src__utils.getTrace = function(stack, formatStacks, filterStacks) {
    let trace = null;
    if (stack == null || !dart.test(formatStacks)) return null;
    if (typeof stack == 'string') {
      trace = src__trace.Trace.parse(stack);
    } else if (core.StackTrace.is(stack)) {
      trace = src__trace.Trace.from(stack);
    } else {
      dart.throw(core.Exception.new(dart.str`Invalid stack type ${dart.runtimeType(stack)} for ${stack}.`));
    }
    if (!dart.test(filterStacks)) return trace;
    return new src__trace.Trace(trace.frames[dartx.takeWhile](dart.fn(frame => frame.package != 'unittest' || frame.member != 'TestCase._runTest', FrameTobool()))).terse.foldFrames(dart.fn(frame => frame.package == 'unittest' || dart.test(frame.isCore), FrameTobool()));
  };
  dart.fn(src__utils.getTrace, dynamicAndboolAndboolToTrace());
  src__expected_function._PLACEHOLDER = dart.const(new core.Object());
  src__expected_function._Func0 = dart.typedef('_Func0', () => dart.functionType(dart.dynamic, []));
  src__expected_function._Func1 = dart.typedef('_Func1', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  src__expected_function._Func2 = dart.typedef('_Func2', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  src__expected_function._Func3 = dart.typedef('_Func3', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic]));
  src__expected_function._Func4 = dart.typedef('_Func4', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]));
  src__expected_function._Func5 = dart.typedef('_Func5', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]));
  src__expected_function._Func6 = dart.typedef('_Func6', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]));
  src__expected_function._IsDoneCallback = dart.typedef('_IsDoneCallback', () => dart.functionType(core.bool, []));
  const _callback = Symbol('_callback');
  const _minExpectedCalls = Symbol('_minExpectedCalls');
  const _maxExpectedCalls = Symbol('_maxExpectedCalls');
  const _isDone = Symbol('_isDone');
  const _reason = Symbol('_reason');
  const _testCase = Symbol('_testCase');
  const _id$ = Symbol('_id');
  const _actualCalls = Symbol('_actualCalls');
  const _complete$ = Symbol('_complete');
  const _max6 = Symbol('_max6');
  const _max5 = Symbol('_max5');
  const _max4 = Symbol('_max4');
  const _max3 = Symbol('_max3');
  const _max2 = Symbol('_max2');
  const _max1 = Symbol('_max1');
  const _max0 = Symbol('_max0');
  const _run = Symbol('_run');
  const _afterRun = Symbol('_afterRun');
  src__expected_function.ExpectedFunction = class ExpectedFunction extends core.Object {
    new(callback, minExpected, maxExpected, opts) {
      let id = opts && 'id' in opts ? opts.id : null;
      let reason = opts && 'reason' in opts ? opts.reason : null;
      let isDone = opts && 'isDone' in opts ? opts.isDone : null;
      this[_callback] = callback;
      this[_minExpectedCalls] = minExpected;
      this[_maxExpectedCalls] = maxExpected == 0 && dart.notNull(minExpected) > 0 ? minExpected : maxExpected;
      this[_isDone] = isDone;
      this[_reason] = reason == null ? '' : dart.str`\n${reason}`;
      this[_testCase] = src__internal_test_case.InternalTestCase.as(unittest.currentTestCase);
      this[_id$] = src__expected_function.ExpectedFunction._makeCallbackId(id, callback);
      this[_actualCalls] = 0;
      this[_complete$] = null;
      unittest.ensureInitialized();
      if (this[_testCase] == null) {
        dart.throw(new core.StateError("No valid test. Did you forget to run your test " + "inside a call to test()?"));
      }
      if (isDone != null || dart.notNull(minExpected) > 0) {
        this[_testCase].callbackFunctionsOutstanding = dart.notNull(this[_testCase].callbackFunctionsOutstanding) + 1;
        this[_complete$] = false;
      } else {
        this[_complete$] = true;
      }
    }
    static _makeCallbackId(id, callback) {
      if (id != null) return dart.str`${id} `;
      let toString = dart.toString(callback);
      let prefix = "Function '";
      let start = toString[dartx.indexOf](prefix);
      if (start == -1) return '';
      start = dart.notNull(start) + dart.notNull(prefix[dartx.length]);
      let end = toString[dartx.indexOf]("'", start);
      if (end == -1) return '';
      return dart.str`${toString[dartx.substring](start, end)} `;
    }
    get func() {
      if (src__expected_function._Func6.is(this[_callback])) return dart.bind(this, _max6);
      if (src__expected_function._Func5.is(this[_callback])) return dart.bind(this, _max5);
      if (src__expected_function._Func4.is(this[_callback])) return dart.bind(this, _max4);
      if (src__expected_function._Func3.is(this[_callback])) return dart.bind(this, _max3);
      if (src__expected_function._Func2.is(this[_callback])) return dart.bind(this, _max2);
      if (src__expected_function._Func1.is(this[_callback])) return dart.bind(this, _max1);
      if (src__expected_function._Func0.is(this[_callback])) return dart.bind(this, _max0);
      dart.throw(new core.ArgumentError('The wrapped function has more than 6 required arguments'));
    }
    [_max0]() {
      return this[_max6]();
    }
    [_max1](a0) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      return this[_max6](a0);
    }
    [_max2](a0, a1) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      if (a1 === void 0) a1 = src__expected_function._PLACEHOLDER;
      return this[_max6](a0, a1);
    }
    [_max3](a0, a1, a2) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      if (a1 === void 0) a1 = src__expected_function._PLACEHOLDER;
      if (a2 === void 0) a2 = src__expected_function._PLACEHOLDER;
      return this[_max6](a0, a1, a2);
    }
    [_max4](a0, a1, a2, a3) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      if (a1 === void 0) a1 = src__expected_function._PLACEHOLDER;
      if (a2 === void 0) a2 = src__expected_function._PLACEHOLDER;
      if (a3 === void 0) a3 = src__expected_function._PLACEHOLDER;
      return this[_max6](a0, a1, a2, a3);
    }
    [_max5](a0, a1, a2, a3, a4) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      if (a1 === void 0) a1 = src__expected_function._PLACEHOLDER;
      if (a2 === void 0) a2 = src__expected_function._PLACEHOLDER;
      if (a3 === void 0) a3 = src__expected_function._PLACEHOLDER;
      if (a4 === void 0) a4 = src__expected_function._PLACEHOLDER;
      return this[_max6](a0, a1, a2, a3, a4);
    }
    [_max6](a0, a1, a2, a3, a4, a5) {
      if (a0 === void 0) a0 = src__expected_function._PLACEHOLDER;
      if (a1 === void 0) a1 = src__expected_function._PLACEHOLDER;
      if (a2 === void 0) a2 = src__expected_function._PLACEHOLDER;
      if (a3 === void 0) a3 = src__expected_function._PLACEHOLDER;
      if (a4 === void 0) a4 = src__expected_function._PLACEHOLDER;
      if (a5 === void 0) a5 = src__expected_function._PLACEHOLDER;
      return this[_run]([a0, a1, a2, a3, a4, a5][dartx.where](dart.fn(a => !dart.equals(a, src__expected_function._PLACEHOLDER), dynamicTobool$())));
    }
    [_run](args) {
      try {
        this[_actualCalls] = dart.notNull(this[_actualCalls]) + 1;
        if (dart.test(this[_testCase].isComplete)) {
          if (this[_testCase].result == unittest.PASS) {
            this[_testCase].error(dart.str`Callback ${this[_id$]}called (${this[_actualCalls]}) after test case ` + dart.str`${this[_testCase].description} had already been marked as ` + dart.str`${this[_testCase].result}.${this[_reason]}`);
          }
          return null;
        } else if (dart.notNull(this[_maxExpectedCalls]) >= 0 && dart.notNull(this[_actualCalls]) > dart.notNull(this[_maxExpectedCalls])) {
          dart.throw(new src__matcher__expect.TestFailure(dart.str`Callback ${this[_id$]}called more times than expected ` + dart.str`(${this[_maxExpectedCalls]}).${this[_reason]}`));
        }
        return core.Function.apply(this[_callback], args[dartx.toList]());
      } catch (error) {
        let stackTrace = dart.stackTrace(error);
        this[_testCase].registerException(error, stackTrace);
        return null;
      }
 finally {
        this[_afterRun]();
      }
    }
    [_afterRun]() {
      if (dart.test(this[_complete$])) return;
      if (dart.notNull(this[_minExpectedCalls]) > 0 && dart.notNull(this[_actualCalls]) < dart.notNull(this[_minExpectedCalls])) return;
      if (this[_isDone] != null && !dart.test(this[_isDone]())) return;
      this[_complete$] = true;
      this[_testCase].markCallbackComplete();
    }
  };
  dart.setSignature(src__expected_function.ExpectedFunction, {
    constructors: () => ({new: dart.definiteFunctionType(src__expected_function.ExpectedFunction, [core.Function, core.int, core.int], {id: core.String, reason: core.String, isDone: VoidTobool()})}),
    methods: () => ({
      [_max0]: dart.definiteFunctionType(dart.dynamic, []),
      [_max1]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic]),
      [_max2]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic]),
      [_max3]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic]),
      [_max4]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_max5]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_max6]: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
      [_run]: dart.definiteFunctionType(dart.dynamic, [core.Iterable]),
      [_afterRun]: dart.definiteFunctionType(dart.void, [])
    }),
    statics: () => ({_makeCallbackId: dart.definiteFunctionType(core.String, [core.String, core.Function])}),
    names: ['_makeCallbackId']
  });
  html_config._showResultsInPage = function(passed, failed, errors, results, isLayoutTest, uncaughtError) {
    if (dart.test(isLayoutTest) && passed == results[dartx.length] && uncaughtError == null) {
      html.document[dartx.body][dartx.innerHtml] = "PASS";
    } else {
      let newBody = new core.StringBuffer();
      newBody.write("<table class='unittest-table'><tbody>");
      newBody.write(passed == results[dartx.length] && uncaughtError == null ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>" : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");
      for (let test_ of results) {
        newBody.write(html_config._toHtml(test_));
      }
      if (uncaughtError != null) {
        newBody.write(dart.str`<tr>\n          <td>--</td>\n          <td class="unittest-error">ERROR</td>\n          <td>Uncaught error: ${uncaughtError}</td>\n        </tr>`);
      }
      if (passed == results[dartx.length] && uncaughtError == null) {
        newBody.write(dart.str`          <tr><td colspan='3' class='unittest-pass'>\n            All ${passed} tests passed\n          </td></tr>`);
      } else {
        newBody.write(dart.str`          <tr><td colspan='3'>Total\n            <span class='unittest-pass'>${passed} passed</span>,\n            <span class='unittest-fail'>${failed} failed</span>\n            <span class='unittest-error'>\n            ${dart.notNull(errors) + (uncaughtError == null ? 0 : 1)} errors</span>\n          </td></tr>`);
      }
      newBody.write("</tbody></table>");
      html.document[dartx.body][dartx.innerHtml] = newBody.toString();
      html.window[dartx.onHashChange].listen(dart.fn(_ => {
        if (html.window[dartx.location][dartx.hash] != null && dart.test(html.window[dartx.location][dartx.hash][dartx.contains]('testFilter'))) {
          html.window[dartx.location][dartx.reload]();
        }
      }, EventTovoid()));
    }
  };
  dart.fn(html_config._showResultsInPage, intAndintAndint__Tovoid());
  html_config._toHtml = function(testCase) {
    if (!dart.test(testCase.isComplete)) {
      return dart.str`        <tr>\n          <td>${testCase.id}</td>\n          <td class="unittest-error">NO STATUS</td>\n          <td>Test did not complete</td>\n        </tr>`;
    }
    let html = dart.str`      <tr>\n        <td>${testCase.id}</td>\n        <td class="unittest-${testCase.result}">\n          ${testCase.result[dartx.toUpperCase]()}\n        </td>\n        <td>\n          <p>Expectation: \n            <a href="#testFilter=${testCase.description}">\n              ${testCase.description}\n            </a>.\n          </p>\n          <pre>${convert.HTML_ESCAPE.convert(testCase.message)}</pre>\n        </td>\n      </tr>`;
    if (testCase.stackTrace != null) {
      html = dart.str`${html}<tr><td></td><td colspan="2"><pre>` + dart.notNull(convert.HTML_ESCAPE.convert(dart.toString(testCase.stackTrace))) + '</pre></td></tr>';
    }
    return html;
  };
  dart.fn(html_config._toHtml, TestCaseToString());
  const _isLayoutTest = Symbol('_isLayoutTest');
  const _onErrorSubscription = Symbol('_onErrorSubscription');
  const _onMessageSubscription = Symbol('_onMessageSubscription');
  const _installHandlers = Symbol('_installHandlers');
  const _uninstallHandlers = Symbol('_uninstallHandlers');
  html_config.HtmlConfiguration = class HtmlConfiguration extends src__simple_configuration.SimpleConfiguration {
    new(isLayoutTest) {
      this[_isLayoutTest] = isLayoutTest;
      this[_onErrorSubscription] = null;
      this[_onMessageSubscription] = null;
      super.new();
    }
    [_installHandlers]() {
      if (this[_onErrorSubscription] == null) {
        this[_onErrorSubscription] = html.window[dartx.onError].listen(dart.fn(e => {
          if (!dart.equals(js.context.get('testExpectsGlobalError'), true)) {
            unittest.handleExternalError(e, '(DOM callback has errors)');
          }
        }, EventTovoid()));
      }
      if (this[_onMessageSubscription] == null) {
        this[_onMessageSubscription] = html.window[dartx.onMessage].listen(dart.fn(e => this.processMessage(e), MessageEventTovoid()));
      }
    }
    [_uninstallHandlers]() {
      if (this[_onErrorSubscription] != null) {
        this[_onErrorSubscription].cancel();
        this[_onErrorSubscription] = null;
      }
      if (this[_onMessageSubscription] != null) {
        this[_onMessageSubscription].cancel();
        this[_onMessageSubscription] = null;
      }
    }
    processMessage(e) {
      if (dart.equals('unittest-suite-external-error', dart.dload(e, 'data'))) {
        unittest.handleExternalError('<unknown>', '(external error detected)');
      }
    }
    onInit() {
      let meta = html.MetaElement._check(html.querySelector('meta[name="dart.unittest"]'));
      unittest.filterStacks = meta == null ? true : !dart.test(meta[dartx.content][dartx.contains]('full-stack-traces'));
      this[_installHandlers]();
      html.window[dartx.postMessage]('unittest-suite-wait-for-done', '*');
    }
    onStart() {
      let hash = html.window[dartx.location][dartx.hash];
      if (hash != null && dart.notNull(hash[dartx.length]) > 1) {
        let params = hash[dartx.substring](1)[dartx.split]('&');
        for (let param of params) {
          let parts = param[dartx.split]('=');
          if (parts[dartx.length] == 2 && parts[dartx.get](0) == 'testFilter') {
            unittest.filterTests(dart.str`^${parts[dartx.get](1)}`);
          }
        }
      }
      super.onStart();
    }
    onSummary(passed, failed, errors, results, uncaughtError) {
      html_config._showResultsInPage(passed, failed, errors, results, this[_isLayoutTest], uncaughtError);
    }
    onDone(success) {
      this[_uninstallHandlers]();
      html.window[dartx.postMessage]('unittest-suite-done', '*');
    }
  };
  dart.setSignature(html_config.HtmlConfiguration, {
    constructors: () => ({new: dart.definiteFunctionType(html_config.HtmlConfiguration, [core.bool])}),
    methods: () => ({
      [_installHandlers]: dart.definiteFunctionType(dart.void, []),
      [_uninstallHandlers]: dart.definiteFunctionType(dart.void, []),
      processMessage: dart.definiteFunctionType(dart.void, [dart.dynamic])
    })
  });
  html_config.useHtmlConfiguration = function(isLayoutTest) {
    if (isLayoutTest === void 0) isLayoutTest = false;
    unittest.unittestConfiguration = dart.test(isLayoutTest) ? html_config._singletonLayout : html_config._singletonNotLayout;
  };
  dart.fn(html_config.useHtmlConfiguration, __Tovoid$());
  dart.defineLazy(html_config, {
    get _singletonLayout() {
      return new html_config.HtmlConfiguration(true);
    }
  });
  dart.defineLazy(html_config, {
    get _singletonNotLayout() {
      return new html_config.HtmlConfiguration(false);
    }
  });
  html_individual_config.HtmlIndividualConfiguration = class HtmlIndividualConfiguration extends html_config.HtmlConfiguration {
    new(isLayoutTest) {
      super.new(isLayoutTest);
    }
    onStart() {
      let uri = core.Uri.parse(html.window[dartx.location][dartx.href]);
      let groups = 'group='[dartx.allMatches](uri.query)[dartx.toList]();
      if (dart.notNull(groups[dartx.length]) > 1) {
        dart.throw(new core.ArgumentError('More than one "group" parameter provided.'));
      }
      let testGroupName = uri.queryParameters[dartx.get]('group');
      if (testGroupName != null) {
        let startsWith = dart.str`${testGroupName}${unittest.groupSep}`;
        unittest.filterTests(dart.fn(tc => tc.description[dartx.startsWith](startsWith), TestCaseTobool()));
      }
      super.onStart();
    }
  };
  dart.setSignature(html_individual_config.HtmlIndividualConfiguration, {
    constructors: () => ({new: dart.definiteFunctionType(html_individual_config.HtmlIndividualConfiguration, [core.bool])})
  });
  html_individual_config.useHtmlIndividualConfiguration = function(isLayoutTest) {
    if (isLayoutTest === void 0) isLayoutTest = false;
    unittest.unittestConfiguration = dart.test(isLayoutTest) ? html_individual_config._singletonLayout : html_individual_config._singletonNotLayout;
  };
  dart.fn(html_individual_config.useHtmlIndividualConfiguration, __Tovoid$());
  dart.defineLazy(html_individual_config, {
    get _singletonLayout() {
      return new html_individual_config.HtmlIndividualConfiguration(true);
    }
  });
  dart.defineLazy(html_individual_config, {
    get _singletonNotLayout() {
      return new html_individual_config.HtmlIndividualConfiguration(false);
    }
  });
  const _isLayoutTest$ = Symbol('_isLayoutTest');
  const _onErrorSubscription$ = Symbol('_onErrorSubscription');
  const _onMessageSubscription$ = Symbol('_onMessageSubscription');
  const _installOnErrorHandler = Symbol('_installOnErrorHandler');
  const _installOnMessageHandler = Symbol('_installOnMessageHandler');
  const _installHandlers$ = Symbol('_installHandlers');
  const _uninstallHandlers$ = Symbol('_uninstallHandlers');
  const _htmlTestCSS = Symbol('_htmlTestCSS');
  const _showInteractiveResultsInPage = Symbol('_showInteractiveResultsInPage');
  const _buildRow = Symbol('_buildRow');
  html_enhanced_config.HtmlEnhancedConfiguration = class HtmlEnhancedConfiguration extends src__simple_configuration.SimpleConfiguration {
    new(isLayoutTest) {
      this[_isLayoutTest$] = isLayoutTest;
      this[_onErrorSubscription$] = null;
      this[_onMessageSubscription$] = null;
      super.new();
    }
    [_installOnErrorHandler]() {
      if (this[_onErrorSubscription$] == null) {
        this[_onErrorSubscription$] = html.window[dartx.onError].listen(dart.fn(e => unittest.handleExternalError(e, '(DOM callback has errors)'), EventTovoid()));
      }
    }
    [_installOnMessageHandler]() {
      if (this[_onMessageSubscription$] == null) {
        this[_onMessageSubscription$] = html.window[dartx.onMessage].listen(dart.fn(e => this.processMessage(e), MessageEventTovoid()));
      }
    }
    [_installHandlers$]() {
      this[_installOnErrorHandler]();
      this[_installOnMessageHandler]();
    }
    [_uninstallHandlers$]() {
      if (this[_onErrorSubscription$] != null) {
        dart.dsend(this[_onErrorSubscription$], 'cancel');
        this[_onErrorSubscription$] = null;
      }
      if (this[_onMessageSubscription$] != null) {
        dart.dsend(this[_onMessageSubscription$], 'cancel');
        this[_onMessageSubscription$] = null;
      }
    }
    processMessage(e) {
      if (dart.equals('unittest-suite-external-error', dart.dload(e, 'data'))) {
        unittest.handleExternalError('<unknown>', '(external error detected)');
      }
    }
    onInit() {
      this[_installHandlers$]();
      let _CSSID = '_unittestcss_';
      let cssElement = html.document[dartx.head][dartx.querySelector](dart.str`#${_CSSID}`);
      if (cssElement == null) {
        cssElement = html.StyleElement.new();
        cssElement[dartx.id] = _CSSID;
        html.document[dartx.head][dartx.append](cssElement);
      }
      cssElement[dartx.text] = this[_htmlTestCSS];
      html.window[dartx.postMessage]('unittest-suite-wait-for-done', '*');
    }
    onStart() {
      this[_installOnErrorHandler]();
    }
    onSummary(passed, failed, errors, results, uncaughtError) {
      this[_showInteractiveResultsInPage](passed, failed, errors, results, this[_isLayoutTest$], uncaughtError);
    }
    onDone(success) {
      this[_uninstallHandlers$]();
      html.window[dartx.postMessage]('unittest-suite-done', '*');
    }
    [_showInteractiveResultsInPage](passed, failed, errors, results, isLayoutTest, uncaughtError) {
      if (dart.test(isLayoutTest) && passed == results[dartx.length]) {
        html.document[dartx.body][dartx.innerHtml] = "PASS";
      } else {
        let te = html.Element.html('<div class="unittest-table"></div>');
        te[dartx.children][dartx.add](html.Element.html(passed == results[dartx.length] ? "<div class='unittest-overall unittest-pass'>PASS</div>" : "<div class='unittest-overall unittest-fail'>FAIL</div>"));
        if (passed == results[dartx.length] && uncaughtError == null) {
          te[dartx.children][dartx.add](html.Element.html(dart.str`          <div class='unittest-pass'>All ${passed} tests passed</div>`));
        } else {
          if (uncaughtError != null) {
            te[dartx.children][dartx.add](html.Element.html(dart.str`            <div class='unittest-summary'>\n              <span class='unittest-error'>Uncaught error: ${uncaughtError}</span>\n            </div>`));
          }
          te[dartx.children][dartx.add](html.Element.html(dart.str`          <div class='unittest-summary'>\n            <span class='unittest-pass'>Total ${passed} passed</span>,\n            <span class='unittest-fail'>${failed} failed</span>,\n            <span class='unittest-error'>\n            ${dart.notNull(errors) + (uncaughtError == null ? 0 : 1)} errors</span>\n          </div>`));
        }
        te[dartx.children][dartx.add](html.Element.html("        <div><button id='btnCollapseAll'>Collapse All</button></div>\n       "));
        te[dartx.querySelector]('#btnCollapseAll')[dartx.onClick].listen(dart.fn(_ => {
          html.document[dartx.querySelectorAll](html.Element)('.unittest-row').forEach(dart.fn(el => el[dartx.attributes][dartx.set]('class', el[dartx.attributes][dartx.get]('class')[dartx.replaceAll]('unittest-row ', 'unittest-row-hidden ')), ElementToString()));
        }, MouseEventTovoid()));
        let previousGroup = '';
        let groupPassFail = true;
        let groupedBy = LinkedHashMapOfString$ListOfTestCase().new();
        for (let t of results) {
          if (!dart.test(groupedBy.containsKey(t.currentGroup))) {
            groupedBy.set(t.currentGroup, ListOfTestCase().new());
          }
          groupedBy.get(t.currentGroup)[dartx.add](t);
        }
        let flattened = ListOfTestCase().new();
        groupedBy.values[dartx.forEach](dart.fn(tList => {
          tList[dartx.sort](dart.fn((tcA, tcB) => dart.notNull(tcA.id) - dart.notNull(tcB.id), TestCaseAndTestCaseToint()));
          flattened[dartx.addAll](tList);
        }, ListOfTestCaseTovoid()));
        let nonAlphanumeric = core.RegExp.new('[^a-z0-9A-Z]');
        for (let test_ of flattened) {
          let safeGroup = test_.currentGroup[dartx.replaceAll](nonAlphanumeric, '_');
          if (test_.currentGroup != previousGroup) {
            previousGroup = test_.currentGroup;
            let testsInGroup = results[dartx.where](dart.fn(t => t.currentGroup == previousGroup, TestCaseTobool()))[dartx.toList]();
            let groupTotalTestCount = testsInGroup[dartx.length];
            let groupTestPassedCount = testsInGroup[dartx.where](dart.fn(t => t.result == 'pass', TestCaseTobool()))[dartx.length];
            groupPassFail = groupTotalTestCount == groupTestPassedCount;
            let passFailClass = "unittest-group-status unittest-group-" + dart.str`status-${groupPassFail ? 'pass' : 'fail'}`;
            te[dartx.children][dartx.add](html.Element.html(dart.str`            <div>\n              <div id='${safeGroup}'\n                   class='unittest-group ${safeGroup} test${safeGroup}'>\n                <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}\n                     class='unittest-row-status'>\n                  <div class='${passFailClass}'></div>\n                </div>\n                <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}>\n                    ${test_.currentGroup}</div>\n                &nbsp;\n                <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}>\n                    (${groupTestPassedCount}/${groupTotalTestCount})</div>\n              </div>\n            </div>`));
            let grp = safeGroup == '' ? null : te[dartx.querySelector](dart.str`#${safeGroup}`);
            if (grp != null) {
              grp[dartx.onClick].listen(dart.fn(_ => {
                let row = html.document[dartx.querySelector](dart.str`.unittest-row-${safeGroup}`);
                if (dart.test(row[dartx.attributes][dartx.get]('class')[dartx.contains]('unittest-row '))) {
                  html.document[dartx.querySelectorAll](html.Element)(dart.str`.unittest-row-${safeGroup}`).forEach(dart.fn(e => e[dartx.attributes][dartx.set]('class', e[dartx.attributes][dartx.get]('class')[dartx.replaceAll]('unittest-row ', 'unittest-row-hidden ')), ElementToString()));
                } else {
                  html.document[dartx.querySelectorAll](html.Element)(dart.str`.unittest-row-${safeGroup}`).forEach(dart.fn(e => e[dartx.attributes][dartx.set]('class', e[dartx.attributes][dartx.get]('class')[dartx.replaceAll]('unittest-row-hidden', 'unittest-row')), ElementToString()));
                }
              }, MouseEventTovoid()));
            }
          }
          this[_buildRow](test_, te, safeGroup, !groupPassFail);
        }
        html.document[dartx.body][dartx.children][dartx.clear]();
        html.document[dartx.body][dartx.children][dartx.add](te);
      }
    }
    [_buildRow](test_, te, groupID, isVisible) {
      let background = dart.str`unittest-row-${test_.id[dartx['%']](2) == 0 ? "even" : "odd"}`;
      let display = dart.str`${dart.test(isVisible) ? "unittest-row" : "unittest-row-hidden"}`;
      function addRowElement(id, status, description) {
        te[dartx.children][dartx.add](html.Element.html(dart.str` <div>\n                <div class='${display} unittest-row-${groupID} ${background}'>\n                  <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}\n                       class='unittest-row-id'>${id}</div>\n                  <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}\n                       class="unittest-row-status unittest-${test_.result}">\n                       ${status}</div>\n                  <div ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "style='display:inline-block' " : ""}\n                       class='unittest-row-description'>${description}</div>\n                </div>\n              </div>`));
      }
      dart.fn(addRowElement, dynamicAnddynamicAnddynamicTodynamic());
      if (!dart.test(test_.isComplete)) {
        addRowElement(dart.str`${test_.id}`, 'NO STATUS', 'Test did not complete.');
        return;
      }
      addRowElement(dart.str`${test_.id}`, dart.str`${test_.result[dartx.toUpperCase]()}`, dart.str`${test_.description}. ${convert.HTML_ESCAPE.convert(test_.message)}`);
      if (test_.stackTrace != null) {
        addRowElement('', '', dart.str`<pre>${convert.HTML_ESCAPE.convert(dart.toString(test_.stackTrace))}</pre>`);
      }
    }
    static get _isIE() {
      return html.window[dartx.navigator][dartx.userAgent][dartx.contains]('MSIE');
    }
    get [_htmlTestCSS]() {
      return '  body{\n    font-size: 14px;\n    font-family: \'Open Sans\', \'Lucida Sans Unicode\', \'Lucida Grande\',' + dart.str` sans-serif;\n    background: WhiteSmoke;\n  }\n\n  .unittest-group\n  {\n    background: rgb(75,75,75);\n    width:98%;\n    color: WhiteSmoke;\n    font-weight: bold;\n    padding: 6px;\n    cursor: pointer;\n\n    /* Provide some visual separation between groups for IE */\n    ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "border-bottom:solid black 1px;" : ""}\n    ${dart.test(html_enhanced_config.HtmlEnhancedConfiguration._isIE) ? "border-top:solid #777777 1px;" : ""}\n\n    background-image: -webkit-linear-gradient(bottom, rgb(50,50,50) 0%, ` + 'rgb(100,100,100) 100%);\n    background-image: -moz-linear-gradient(bottom, rgb(50,50,50) 0%, ' + 'rgb(100,100,100) 100%);\n    background-image: -ms-linear-gradient(bottom, rgb(50,50,50) 0%, ' + 'rgb(100,100,100) 100%);\n    background-image: linear-gradient(bottom, rgb(50,50,50) 0%, ' + 'rgb(100,100,100) 100%);\n\n    display: -webkit-box;\n    display: -moz-box;\n    display: -ms-box;\n    display: box;\n\n    -webkit-box-orient: horizontal;\n    -moz-box-orient: horizontal;\n    -ms-box-orient: horizontal;\n    box-orient: horizontal;\n\n    -webkit-box-align: center;\n    -moz-box-align: center;\n    -ms-box-align: center;\n    box-align: center;\n   }\n\n  .unittest-group-status\n  {\n    width: 20px;\n    height: 20px;\n    border-radius: 20px;\n    margin-left: 10px;\n  }\n\n  .unittest-group-status-pass{\n    background: Green;\n    background: ' + '-webkit-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);\n    background: ' + '-moz-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);\n    background: ' + '-ms-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);\n    background: ' + 'radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);\n  }\n\n  .unittest-group-status-fail{\n    background: Red;\n    background: ' + '-webkit-radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);\n    background: ' + '-moz-radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);\n    background: ' + '-ms-radial-gradient(center, ellipse cover, #AAFFAA 0%,Green 100%);\n    background: radial-gradient(center, ellipse cover, #FFAAAA 0%,Red 100%);\n  }\n\n  .unittest-overall{\n    font-size: 20px;\n  }\n\n  .unittest-summary{\n    font-size: 18px;\n  }\n\n  .unittest-pass{\n    color: Green;\n  }\n\n  .unittest-fail, .unittest-error\n  {\n    color: Red;\n  }\n\n  .unittest-row\n  {\n    display: -webkit-box;\n    display: -moz-box;\n    display: -ms-box;\n    display: box;\n    -webkit-box-orient: horizontal;\n    -moz-box-orient: horizontal;\n    -ms-box-orient: horizontal;\n    box-orient: horizontal;\n    width: 100%;\n  }\n\n  .unittest-row-hidden\n  {\n    display: none;\n  }\n\n  .unittest-row-odd\n  {\n    background: WhiteSmoke;\n  }\n\n  .unittest-row-even\n  {\n    background: #E5E5E5;\n  }\n\n  .unittest-row-id\n  {\n    width: 3em;\n  }\n\n  .unittest-row-status\n  {\n    width: 4em;\n  }\n\n  .unittest-row-description\n  {\n  }\n\n  ';
    }
  };
  dart.setSignature(html_enhanced_config.HtmlEnhancedConfiguration, {
    constructors: () => ({new: dart.definiteFunctionType(html_enhanced_config.HtmlEnhancedConfiguration, [core.bool])}),
    methods: () => ({
      [_installOnErrorHandler]: dart.definiteFunctionType(dart.void, []),
      [_installOnMessageHandler]: dart.definiteFunctionType(dart.void, []),
      [_installHandlers$]: dart.definiteFunctionType(dart.void, []),
      [_uninstallHandlers$]: dart.definiteFunctionType(dart.void, []),
      processMessage: dart.definiteFunctionType(dart.void, [dart.dynamic]),
      [_showInteractiveResultsInPage]: dart.definiteFunctionType(dart.void, [core.int, core.int, core.int, core.List$(src__test_case.TestCase), core.bool, core.String]),
      [_buildRow]: dart.definiteFunctionType(dart.void, [src__test_case.TestCase, html.Element, core.String, core.bool])
    })
  });
  html_enhanced_config.useHtmlEnhancedConfiguration = function(isLayoutTest) {
    if (isLayoutTest === void 0) isLayoutTest = false;
    unittest.unittestConfiguration = dart.test(isLayoutTest) ? html_enhanced_config._singletonLayout : html_enhanced_config._singletonNotLayout;
  };
  dart.fn(html_enhanced_config.useHtmlEnhancedConfiguration, __Tovoid$());
  dart.defineLazy(html_enhanced_config, {
    get _singletonLayout() {
      return new html_enhanced_config.HtmlEnhancedConfiguration(true);
    }
  });
  dart.defineLazy(html_enhanced_config, {
    get _singletonNotLayout() {
      return new html_enhanced_config.HtmlEnhancedConfiguration(false);
    }
  });
  // Exports:
  exports.unittest = unittest;
  exports.src__configuration = src__configuration;
  exports.src__simple_configuration = src__simple_configuration;
  exports.src__matcher = src__matcher;
  exports.src__matcher__core_matchers = src__matcher__core_matchers;
  exports.src__matcher__description = src__matcher__description;
  exports.src__matcher__interfaces = src__matcher__interfaces;
  exports.src__matcher__pretty_print = src__matcher__pretty_print;
  exports.src__matcher__util = src__matcher__util;
  exports.src__matcher__error_matchers = src__matcher__error_matchers;
  exports.src__matcher__expect = src__matcher__expect;
  exports.src__matcher__future_matchers = src__matcher__future_matchers;
  exports.src__matcher__iterable_matchers = src__matcher__iterable_matchers;
  exports.src__matcher__map_matchers = src__matcher__map_matchers;
  exports.src__matcher__numeric_matchers = src__matcher__numeric_matchers;
  exports.src__matcher__operator_matchers = src__matcher__operator_matchers;
  exports.src__matcher__prints_matcher = src__matcher__prints_matcher;
  exports.src__matcher__string_matchers = src__matcher__string_matchers;
  exports.src__matcher__throws_matcher = src__matcher__throws_matcher;
  exports.src__matcher__throws_matchers = src__matcher__throws_matchers;
  exports.src__internal_test_case = src__internal_test_case;
  exports.src__test_environment = src__test_environment;
  exports.src__group_context = src__group_context;
  exports.src__utils = src__utils;
  exports.src__test_case = src__test_case;
  exports.src__expected_function = src__expected_function;
  exports.html_config = html_config;
  exports.html_individual_config = html_individual_config;
  exports.html_enhanced_config = html_enhanced_config;
});
