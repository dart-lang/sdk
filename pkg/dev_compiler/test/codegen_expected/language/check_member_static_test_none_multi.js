dart_library.library('language/check_member_static_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__check_member_static_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const check_member_static_test_none_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  check_member_static_test_none_multi.A = class A extends core.Object {
    new() {
      this.b = null;
    }
  };
  check_member_static_test_none_multi.A.a = null;
  check_member_static_test_none_multi.B = class B extends check_member_static_test_none_multi.A {
    new() {
      super.new();
    }
  };
  check_member_static_test_none_multi.C = class C extends check_member_static_test_none_multi.B {};
  check_member_static_test_none_multi.main = function() {
    new check_member_static_test_none_multi.C();
  };
  dart.fn(check_member_static_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.check_member_static_test_none_multi = check_member_static_test_none_multi;
});
