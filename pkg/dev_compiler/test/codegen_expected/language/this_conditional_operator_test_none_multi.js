dart_library.library('language/this_conditional_operator_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__this_conditional_operator_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const this_conditional_operator_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  this_conditional_operator_test_none_multi.B = class B extends core.Object {
    new() {
      this.field = 1;
    }
    namedConstructor() {
      this.field = 1;
    }
    method() {
      return 1;
    }
    forward() {
      this.field = 1;
    }
    test() {
      this == null ? null : this.field = 1;
      this == null ? null : this.field = dart.notNull(this.field) + 1;
      this.field;
      this.method();
    }
  };
  dart.defineNamedConstructor(this_conditional_operator_test_none_multi.B, 'namedConstructor');
  dart.defineNamedConstructor(this_conditional_operator_test_none_multi.B, 'forward');
  dart.setSignature(this_conditional_operator_test_none_multi.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(this_conditional_operator_test_none_multi.B, []),
      namedConstructor: dart.definiteFunctionType(this_conditional_operator_test_none_multi.B, []),
      forward: dart.definiteFunctionType(this_conditional_operator_test_none_multi.B, [])
    }),
    methods: () => ({
      method: dart.definiteFunctionType(dart.dynamic, []),
      test: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  this_conditional_operator_test_none_multi.main = function() {
    new this_conditional_operator_test_none_multi.B.forward().test();
  };
  dart.fn(this_conditional_operator_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.this_conditional_operator_test_none_multi = this_conditional_operator_test_none_multi;
});
