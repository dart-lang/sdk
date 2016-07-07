dart_library.library('language/cyclic_class_member_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__cyclic_class_member_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cyclic_class_member_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_class_member_test_none_multi.A = class A extends core.Object {
    static foo() {}
  };
  dart.setSignature(cyclic_class_member_test_none_multi.A, {
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  cyclic_class_member_test_none_multi.main = function() {
    new cyclic_class_member_test_none_multi.A();
  };
  dart.fn(cyclic_class_member_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_class_member_test_none_multi = cyclic_class_member_test_none_multi;
});
