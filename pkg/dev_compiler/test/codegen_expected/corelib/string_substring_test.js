dart_library.library('corelib/string_substring_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_substring_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_substring_test = Object.create(null);
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_substring_test.main = function() {
    expect$.Expect.equals(""[dartx.substring](0), "");
    expect$.Expect.throws(dart.fn(() => ""[dartx.substring](1), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => ""[dartx.substring](-1), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.equals("abc"[dartx.substring](0), "abc");
    expect$.Expect.equals("abc"[dartx.substring](1), "bc");
    expect$.Expect.equals("abc"[dartx.substring](2), "c");
    expect$.Expect.equals("abc"[dartx.substring](3), "");
    expect$.Expect.throws(dart.fn(() => "abc"[dartx.substring](4), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => "abc"[dartx.substring](-1), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.equals(""[dartx.substring](0, null), "");
    expect$.Expect.throws(dart.fn(() => ""[dartx.substring](1, null), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => ""[dartx.substring](-1, null), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.equals("abc"[dartx.substring](0, null), "abc");
    expect$.Expect.equals("abc"[dartx.substring](1, null), "bc");
    expect$.Expect.equals("abc"[dartx.substring](2, null), "c");
    expect$.Expect.equals("abc"[dartx.substring](3, null), "");
    expect$.Expect.throws(dart.fn(() => "abc"[dartx.substring](4, null), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => "abc"[dartx.substring](-1, null), VoidToString()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(string_substring_test.main, VoidTodynamic());
  // Exports:
  exports.string_substring_test = string_substring_test;
});
