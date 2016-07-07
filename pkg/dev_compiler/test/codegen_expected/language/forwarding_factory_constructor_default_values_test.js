dart_library.library('language/forwarding_factory_constructor_default_values_test', null, /* Imports */[
  'dart_sdk'
], function load__forwarding_factory_constructor_default_values_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const forwarding_factory_constructor_default_values_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  forwarding_factory_constructor_default_values_test.main = function() {
    let a = forwarding_factory_constructor_default_values_test.A.a1();
    a.test();
  };
  dart.fn(forwarding_factory_constructor_default_values_test.main, VoidTodynamic());
  forwarding_factory_constructor_default_values_test.A = class A extends core.Object {
    new(opts) {
      let condition = opts && 'condition' in opts ? opts.condition : true;
      this.condition = condition;
    }
    static a1(opts) {
      return new forwarding_factory_constructor_default_values_test._A1.boo(opts);
    }
    test() {
      if (this.condition != true) {
        dart.throw("FAILED");
      }
    }
  };
  dart.setSignature(forwarding_factory_constructor_default_values_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(forwarding_factory_constructor_default_values_test.A, [], {condition: core.bool}),
      a1: dart.definiteFunctionType(forwarding_factory_constructor_default_values_test.A, [], {condition: dart.dynamic})
    }),
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  forwarding_factory_constructor_default_values_test._A1 = class _A1 extends forwarding_factory_constructor_default_values_test.A {
    boo(opts) {
      let condition = opts && 'condition' in opts ? opts.condition : true;
      super.new({condition: core.bool._check(condition)});
    }
  };
  dart.defineNamedConstructor(forwarding_factory_constructor_default_values_test._A1, 'boo');
  dart.setSignature(forwarding_factory_constructor_default_values_test._A1, {
    constructors: () => ({boo: dart.definiteFunctionType(forwarding_factory_constructor_default_values_test._A1, [], {condition: dart.dynamic})})
  });
  // Exports:
  exports.forwarding_factory_constructor_default_values_test = forwarding_factory_constructor_default_values_test;
});
