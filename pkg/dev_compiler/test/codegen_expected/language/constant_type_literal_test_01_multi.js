dart_library.library('language/constant_type_literal_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__constant_type_literal_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constant_type_literal_test_01_multi = Object.create(null);
  let C = () => (C = dart.constFn(constant_type_literal_test_01_multi.C$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constant_type_literal_test_01_multi.C$ = dart.generic(T => {
    class C extends core.Object {
      m() {
        let lst = dart.constList([dart.wrapType(T)], core.Type);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({m: dart.definiteFunctionType(dart.void, [])})
    });
    return C;
  });
  constant_type_literal_test_01_multi.C = C();
  constant_type_literal_test_01_multi.main = function() {
    new constant_type_literal_test_01_multi.C().m();
  };
  dart.fn(constant_type_literal_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.constant_type_literal_test_01_multi = constant_type_literal_test_01_multi;
});
