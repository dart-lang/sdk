dart_library.library('language/type_variable_conflict2_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_conflict2_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_conflict2_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(type_variable_conflict2_test_none_multi.C$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  type_variable_conflict2_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {
      noSuchMethod(im) {
        expect$.Expect.equals(const$ || (const$ = dart.const(core.Symbol.new('T'))), im.memberName);
        return 42;
      }
    }
    dart.addTypeTests(C);
    return C;
  });
  type_variable_conflict2_test_none_multi.C = C();
  type_variable_conflict2_test_none_multi.main = function() {
  };
  dart.fn(type_variable_conflict2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.type_variable_conflict2_test_none_multi = type_variable_conflict2_test_none_multi;
});
