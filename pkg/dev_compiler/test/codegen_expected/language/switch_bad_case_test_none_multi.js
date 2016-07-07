dart_library.library('language/switch_bad_case_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_bad_case_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_bad_case_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  switch_bad_case_test_none_multi.main = function() {
    expect$.Expect.equals("IV", switch_bad_case_test_none_multi.caesarSays(4));
    expect$.Expect.equals(null, switch_bad_case_test_none_multi.caesarSays(2));
    expect$.Expect.equals(null, switch_bad_case_test_none_multi.archimedesSays(3.14));
  };
  dart.fn(switch_bad_case_test_none_multi.main, VoidTovoid());
  switch_bad_case_test_none_multi.caesarSays = function(n) {
    switch (n) {
      case 1:
      {
        return "I";
      }
      case 4:
      {
        return "IV";
      }
    }
    return null;
  };
  dart.fn(switch_bad_case_test_none_multi.caesarSays, dynamicTodynamic());
  switch_bad_case_test_none_multi.archimedesSays = function(n) {
    return null;
  };
  dart.fn(switch_bad_case_test_none_multi.archimedesSays, dynamicTodynamic());
  // Exports:
  exports.switch_bad_case_test_none_multi = switch_bad_case_test_none_multi;
});
