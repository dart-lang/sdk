dart_library.library('language/regress_21912_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_21912_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_21912_test_none_multi = Object.create(null);
  let Function2 = () => (Function2 = dart.constFn(regress_21912_test_none_multi.Function2$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_21912_test_none_multi.A = class A extends core.Object {};
  regress_21912_test_none_multi.B = class B extends regress_21912_test_none_multi.A {};
  regress_21912_test_none_multi.Function2$ = dart.generic((S, T) => {
    const Function2 = dart.typedef('Function2', () => dart.functionType(T, [S]));
    return Function2;
  });
  regress_21912_test_none_multi.Function2 = Function2();
  regress_21912_test_none_multi.AToB = dart.typedef('AToB', () => dart.functionType(regress_21912_test_none_multi.B, [regress_21912_test_none_multi.A]));
  regress_21912_test_none_multi.BToA = dart.typedef('BToA', () => dart.functionType(regress_21912_test_none_multi.A, [regress_21912_test_none_multi.B]));
  regress_21912_test_none_multi.main = function() {
    {
      let t1 = null;
      let t2 = null;
      let left = null;
    }
  };
  dart.fn(regress_21912_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.regress_21912_test_none_multi = regress_21912_test_none_multi;
});
