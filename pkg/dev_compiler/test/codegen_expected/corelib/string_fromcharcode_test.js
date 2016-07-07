dart_library.library('corelib/string_fromcharcode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_fromcharcode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_fromcharcode_test = Object.create(null);
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_fromcharcode_test.main = function() {
    expect$.Expect.equals("A", core.String.fromCharCode(65));
    expect$.Expect.equals("B", core.String.fromCharCode(66));
    let gClef = core.String.fromCharCode(119070);
    expect$.Expect.equals(2, gClef[dartx.length]);
    expect$.Expect.equals(55348, gClef[dartx.codeUnitAt](0));
    expect$.Expect.equals(56606, gClef[dartx.codeUnitAt](1));
    let unmatched = core.String.fromCharCode(55296);
    expect$.Expect.equals(1, unmatched[dartx.length]);
    expect$.Expect.equals(55296, unmatched[dartx.codeUnitAt](0));
    unmatched = core.String.fromCharCode(56320);
    expect$.Expect.equals(1, unmatched[dartx.length]);
    expect$.Expect.equals(56320, unmatched[dartx.codeUnitAt](0));
    expect$.Expect.throws(dart.fn(() => core.String.fromCharCode(-1), VoidToString()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.String.fromCharCode(1114112), VoidToString()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.String.fromCharCode(1114113), VoidToString()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
  };
  dart.fn(string_fromcharcode_test.main, VoidTodynamic());
  // Exports:
  exports.string_fromcharcode_test = string_fromcharcode_test;
});
