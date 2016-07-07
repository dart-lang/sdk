dart_library.library('language/class_override_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__class_override_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const class_override_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_override_test_none_multi.A = class A extends core.Object {
    foo() {}
  };
  dart.setSignature(class_override_test_none_multi.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  class_override_test_none_multi.B = class B extends class_override_test_none_multi.A {};
  class_override_test_none_multi.main = function() {
    let instance = new class_override_test_none_multi.B();
    try {
      instance.foo();
    } finally {
    }
    core.print("Success");
  };
  dart.fn(class_override_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.class_override_test_none_multi = class_override_test_none_multi;
});
