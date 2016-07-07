dart_library.library('language/check_method_override_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__check_method_override_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const check_method_override_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  check_method_override_test_none_multi.A = class A extends core.Object {
    f(x) {
      if (x === void 0) x = null;
    }
    foo(a, x, y) {
      if (x === void 0) x = null;
      if (y === void 0) y = null;
    }
  };
  dart.setSignature(check_method_override_test_none_multi.A, {
    methods: () => ({
      f: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic]),
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic])
    })
  });
  check_method_override_test_none_multi.C = class C extends check_method_override_test_none_multi.A {};
  check_method_override_test_none_multi.main = function() {
    new check_method_override_test_none_multi.A().foo(2);
    new check_method_override_test_none_multi.C().foo(1);
  };
  dart.fn(check_method_override_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.check_method_override_test_none_multi = check_method_override_test_none_multi;
});
