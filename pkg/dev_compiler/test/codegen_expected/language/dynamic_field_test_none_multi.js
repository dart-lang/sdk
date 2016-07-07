dart_library.library('language/dynamic_field_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__dynamic_field_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const dynamic_field_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dynamic_field_test_none_multi.C = class C extends core.Object {
    foo() {}
    bar() {}
  };
  dart.setSignature(dynamic_field_test_none_multi.C, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  dynamic_field_test_none_multi.A = class A extends dynamic_field_test_none_multi.C {
    new() {
      this.a = null;
      this.b = null;
    }
  };
  dynamic_field_test_none_multi.main = function() {
    let a = new dynamic_field_test_none_multi.A();
    a.a = 1;
    a.b = a;
  };
  dart.fn(dynamic_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.dynamic_field_test_none_multi = dynamic_field_test_none_multi;
});
