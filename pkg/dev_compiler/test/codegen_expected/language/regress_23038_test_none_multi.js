dart_library.library('language/regress_23038_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_23038_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_23038_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(regress_23038_test_none_multi.C$()))();
  let COfint = () => (COfint = dart.constFn(regress_23038_test_none_multi.C$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_23038_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      constructors: () => ({new: dart.definiteFunctionType(regress_23038_test_none_multi.C$(T), [])})
    });
    return C;
  });
  regress_23038_test_none_multi.C = C();
  let const$;
  regress_23038_test_none_multi.main = function() {
    const$ || (const$ = dart.const(new (COfint())()));
  };
  dart.fn(regress_23038_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_23038_test_none_multi = regress_23038_test_none_multi;
});
