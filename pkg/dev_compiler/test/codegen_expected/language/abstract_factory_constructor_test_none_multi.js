dart_library.library('language/abstract_factory_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__abstract_factory_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const abstract_factory_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  abstract_factory_constructor_test_none_multi.A1 = class A1 extends core.Object {
    new() {
    }
    static make() {
      return new abstract_factory_constructor_test_none_multi.B();
    }
  };
  dart.setSignature(abstract_factory_constructor_test_none_multi.A1, {
    constructors: () => ({
      new: dart.definiteFunctionType(abstract_factory_constructor_test_none_multi.A1, []),
      make: dart.definiteFunctionType(abstract_factory_constructor_test_none_multi.A1, [])
    })
  });
  abstract_factory_constructor_test_none_multi.B = class B extends abstract_factory_constructor_test_none_multi.A1 {
    new() {
      super.new();
    }
    method() {}
  };
  dart.setSignature(abstract_factory_constructor_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(abstract_factory_constructor_test_none_multi.B, [])}),
    methods: () => ({method: dart.definiteFunctionType(dart.dynamic, [])})
  });
  abstract_factory_constructor_test_none_multi.A2 = class A2 extends core.Object {
    make() {
    }
  };
  dart.defineNamedConstructor(abstract_factory_constructor_test_none_multi.A2, 'make');
  dart.setSignature(abstract_factory_constructor_test_none_multi.A2, {
    constructors: () => ({make: dart.definiteFunctionType(abstract_factory_constructor_test_none_multi.A2, [])})
  });
  abstract_factory_constructor_test_none_multi.main = function() {
    abstract_factory_constructor_test_none_multi.A1.make();
  };
  dart.fn(abstract_factory_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.abstract_factory_constructor_test_none_multi = abstract_factory_constructor_test_none_multi;
});
