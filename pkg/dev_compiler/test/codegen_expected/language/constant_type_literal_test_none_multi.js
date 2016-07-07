dart_library.library('language/constant_type_literal_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constant_type_literal_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constant_type_literal_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(constant_type_literal_test_none_multi.C$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  constant_type_literal_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {
      m() {
        let lst = const$ || (const$ = dart.constList([], dart.dynamic));
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({m: dart.definiteFunctionType(dart.void, [])})
    });
    return C;
  });
  constant_type_literal_test_none_multi.C = C();
  constant_type_literal_test_none_multi.main = function() {
    new constant_type_literal_test_none_multi.C().m();
  };
  dart.fn(constant_type_literal_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constant_type_literal_test_none_multi = constant_type_literal_test_none_multi;
});
