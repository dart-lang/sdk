dart_library.library('corelib/unicode2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unicode2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unicode2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  unicode2_test.testPhrase = "The quick brown fox jumps over the lazy dog.";
  unicode2_test.testCodepoints = dart.constList([84, 104, 101, 32, 113, 117, 105, 99, 107, 32, 98, 114, 111, 119, 110, 32, 102, 111, 120, 32, 106, 117, 109, 112, 115, 32, 111, 118, 101, 114, 32, 116, 104, 101, 32, 108, 97, 122, 121, 32, 100, 111, 103, 46], core.int);
  unicode2_test.main = function() {
    unicode2_test.testCodepointsToString();
    unicode2_test.testStringCharCodes();
    unicode2_test.testEmptyStringFromCharCodes();
    unicode2_test.testEmptyStringCharCodes();
  };
  dart.fn(unicode2_test.main, VoidTodynamic());
  unicode2_test.testStringCharCodes = function() {
    expect$.Expect.listEquals(unicode2_test.testCodepoints, unicode2_test.testPhrase[dartx.codeUnits]);
  };
  dart.fn(unicode2_test.testStringCharCodes, VoidTovoid());
  unicode2_test.testCodepointsToString = function() {
    expect$.Expect.stringEquals(unicode2_test.testPhrase, core.String.fromCharCodes(unicode2_test.testCodepoints));
  };
  dart.fn(unicode2_test.testCodepointsToString, VoidTovoid());
  unicode2_test.testEmptyStringFromCharCodes = function() {
    expect$.Expect.stringEquals("", core.String.fromCharCodes(JSArrayOfint().of([])));
  };
  dart.fn(unicode2_test.testEmptyStringFromCharCodes, VoidTovoid());
  unicode2_test.testEmptyStringCharCodes = function() {
    expect$.Expect.listEquals([], ""[dartx.codeUnits]);
  };
  dart.fn(unicode2_test.testEmptyStringCharCodes, VoidTovoid());
  // Exports:
  exports.unicode2_test = unicode2_test;
});
