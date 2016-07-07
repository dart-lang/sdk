dart_library.library('language/const_constructor_nonconst_field_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_constructor_nonconst_field_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_constructor_nonconst_field_test_none_multi = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_constructor_nonconst_field_test_none_multi.A = class A extends core.Object {
    new() {
      this.j = 1;
    }
  };
  dart.setSignature(const_constructor_nonconst_field_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(const_constructor_nonconst_field_test_none_multi.A, [])})
  });
  const_constructor_nonconst_field_test_none_multi.f = function() {
    return 3;
  };
  dart.fn(const_constructor_nonconst_field_test_none_multi.f, VoidToint());
  let const$;
  const_constructor_nonconst_field_test_none_multi.main = function() {
    expect$.Expect.equals((const$ || (const$ = dart.const(new const_constructor_nonconst_field_test_none_multi.A()))).j, 1);
  };
  dart.fn(const_constructor_nonconst_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_constructor_nonconst_field_test_none_multi = const_constructor_nonconst_field_test_none_multi;
});
