dart_library.library('corelib/string_to_lower_case_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_to_lower_case_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_to_lower_case_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  string_to_lower_case_test.testOneByteSting = function() {
    let oneByteString = core.String.fromCharCodes(ListOfint().generate(256, dart.fn(i => i, intToint())))[dartx.toLowerCase]();
    let twoByteString = core.String.fromCharCodes(ListOfint().generate(512, dart.fn(i => i, intToint())))[dartx.toLowerCase]();
    expect$.Expect.isTrue(twoByteString[dartx.codeUnits][dartx.any](dart.fn(u => dart.notNull(u) >= 256, intTobool())));
    expect$.Expect.equals(oneByteString, twoByteString[dartx.substring](0, 256));
  };
  dart.fn(string_to_lower_case_test.testOneByteSting, VoidTovoid());
  string_to_lower_case_test.main = function() {
    string_to_lower_case_test.testOneByteSting();
  };
  dart.fn(string_to_lower_case_test.main, VoidTovoid());
  // Exports:
  exports.string_to_lower_case_test = string_to_lower_case_test;
});
