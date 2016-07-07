dart_library.library('language/constructor_duplicate_initializers_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor_duplicate_initializers_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor_duplicate_initializers_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_duplicate_initializers_test_none_multi.Class = class Class extends core.Object {
    new(v) {
      this.field_ = v;
    }
    field(field_) {
      this.field_ = field_;
    }
    two_fields(field_) {
      this.field_ = field_;
    }
  };
  dart.defineNamedConstructor(constructor_duplicate_initializers_test_none_multi.Class, 'field');
  dart.defineNamedConstructor(constructor_duplicate_initializers_test_none_multi.Class, 'two_fields');
  dart.setSignature(constructor_duplicate_initializers_test_none_multi.Class, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_duplicate_initializers_test_none_multi.Class, [dart.dynamic]),
      field: dart.definiteFunctionType(constructor_duplicate_initializers_test_none_multi.Class, [dart.dynamic]),
      two_fields: dart.definiteFunctionType(constructor_duplicate_initializers_test_none_multi.Class, [dart.dynamic])
    })
  });
  constructor_duplicate_initializers_test_none_multi.main = function() {
    new constructor_duplicate_initializers_test_none_multi.Class(42);
    new constructor_duplicate_initializers_test_none_multi.Class.field(42);
    new constructor_duplicate_initializers_test_none_multi.Class.two_fields(42);
  };
  dart.fn(constructor_duplicate_initializers_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_duplicate_initializers_test_none_multi = constructor_duplicate_initializers_test_none_multi;
});
