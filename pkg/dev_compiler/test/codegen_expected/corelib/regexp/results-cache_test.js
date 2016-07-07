dart_library.library('corelib/regexp/results-cache_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__results$45cache_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const results$45cache_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  results$45cache_test.main = function() {
    let string = "Friends, Romans, countrymen, lend me your ears!  \n  I come to bury Caesar, not to praise him.        \n  The evil that men do lives after them,           \n  The good is oft interred with their bones;       \n  So let it be with Caesar. The noble Brutus       \n  Hath told you Caesar was ambitious;              \n  If it were so, it was a grievous fault,          \n  And grievously hath Caesar answer'd it.          \n  Here, under leave of Brutus and the rest-        \n  For Brutus is an honorable man;                  \n  So are they all, all honorable men-              \n  Come I to speak in Caesar's funeral.             \n  He was my friend, faithful and just to me;       \n  But Brutus says he was ambitious,                \n  And Brutus is an honorable man.                  \n  He hath brought many captives home to Rome,      \n  Whose ransoms did the general coffers fill.      \n  Did this in Caesar seem ambitious?               \n  When that the poor have cried, Caesar hath wept; \n  Ambition should be made of sterner stuff:        \n  Yet Brutus says he was ambitious,                \n  And Brutus is an honorable man.                  \n  You all did see that on the Lupercal             \n  I thrice presented him a kingly crown,           \n  Which he did thrice refuse. Was this ambition?   \n  Yet Brutus says he was ambitious,                \n  And sure he is an honorable man.                 \n  I speak not to disprove what Brutus spoke,       \n  But here I am to speak what I do know.           \n  You all did love him once, not without cause;    \n  What cause withholds you then to mourn for him?  \n  O judgement, thou art fled to brutish beasts,    \n  And men have lost their reason. Bear with me;    \n  My heart is in the coffin there with Caesar,     \n  And I must pause till it come back to me.";
    let replaced = string[dartx.replaceAll](core.RegExp.new("\\b\\w+\\b"), "foo");
    for (let i = 0; i < 3; i++) {
      v8_regexp_utils.assertEquals(replaced, string[dartx.replaceAll](core.RegExp.new("\\b\\w+\\b"), "foo"));
    }
    let words = string[dartx.split](" ");
    v8_regexp_utils.assertEquals("Friends,", words[dartx.get](0));
    words[dartx.set](0, "Enemies,");
    words = string[dartx.split](" ");
    v8_regexp_utils.assertEquals("Friends,", words[dartx.get](0));
  };
  dart.fn(results$45cache_test.main, VoidTovoid$());
  v8_regexp_utils.assertEquals = function(actual, expected, message) {
    if (message === void 0) message = null;
    expect$.Expect.equals(actual, expected, message);
  };
  dart.fn(v8_regexp_utils.assertEquals, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.assertTrue = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isTrue(actual, message);
  };
  dart.fn(v8_regexp_utils.assertTrue, dynamic__Tovoid());
  v8_regexp_utils.assertFalse = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isFalse(actual, message);
  };
  dart.fn(v8_regexp_utils.assertFalse, dynamic__Tovoid());
  v8_regexp_utils.assertThrows = function(fn, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.throws(VoidTovoid()._check(fn), null, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertThrows, dynamic__Tovoid$());
  v8_regexp_utils.assertNull = function(actual, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.isNull(actual, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertNull, dynamic__Tovoid$());
  v8_regexp_utils.assertToStringEquals = function(str, match, testid) {
    let actual = [];
    for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(match, 'groupCount'))); i++) {
      let g = dart.dsend(match, 'group', i);
      actual[dartx.add](g == null ? "" : g);
    }
    expect$.Expect.equals(str, actual[dartx.join](","), dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertToStringEquals, dynamicAnddynamicAndnumTovoid());
  v8_regexp_utils.shouldBeTrue = function(actual) {
    expect$.Expect.isTrue(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeTrue, dynamicTovoid());
  v8_regexp_utils.shouldBeFalse = function(actual) {
    expect$.Expect.isFalse(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeFalse, dynamicTovoid());
  v8_regexp_utils.shouldBeNull = function(actual) {
    expect$.Expect.isNull(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeNull, dynamicTovoid());
  v8_regexp_utils.shouldBe = function(actual, expected, message) {
    if (message === void 0) message = null;
    if (expected == null) {
      expect$.Expect.isNull(actual, message);
    } else {
      expect$.Expect.equals(dart.dload(expected, 'length'), dart.dsend(dart.dload(actual, 'groupCount'), '+', 1));
      for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(actual, 'groupCount'))); i++) {
        expect$.Expect.equals(dart.dindex(expected, i), dart.dsend(actual, 'group', i), message);
      }
    }
  };
  dart.fn(v8_regexp_utils.shouldBe, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.firstMatch = function(str, pattern) {
    return pattern.firstMatch(str);
  };
  dart.fn(v8_regexp_utils.firstMatch, StringAndRegExpToMatch());
  v8_regexp_utils.allStringMatches = function(str, pattern) {
    return pattern.allMatches(str)[dartx.map](core.String)(dart.fn(m => m.group(0), MatchToString()))[dartx.toList]();
  };
  dart.fn(v8_regexp_utils.allStringMatches, StringAndRegExpToListOfString());
  v8_regexp_utils.description = function(str) {
  };
  dart.fn(v8_regexp_utils.description, dynamicTovoid());
  // Exports:
  exports.results$45cache_test = results$45cache_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
