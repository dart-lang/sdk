dart_library.library('language/constructor_name_clash_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_name_clash_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_name_clash_test = Object.create(null);
  const constructor_name_clash_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_name_clash_lib.A = class A extends core.Object {
    new() {
      constructor_name_clash_lib.global = dart.notNull(constructor_name_clash_lib.global) + 10;
      try {
      } catch (e) {
      }

    }
  };
  dart.setSignature(constructor_name_clash_lib.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_name_clash_lib.A, [])})
  });
  constructor_name_clash_test.A = class A extends constructor_name_clash_lib.A {
    new() {
      super.new();
      constructor_name_clash_lib.global = dart.notNull(constructor_name_clash_lib.global) + 100;
      try {
      } catch (e) {
      }

    }
  };
  dart.setSignature(constructor_name_clash_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_name_clash_test.A, [])})
  });
  constructor_name_clash_test.main = function() {
    new constructor_name_clash_test.A();
    expect$.Expect.equals(110, constructor_name_clash_lib.global);
  };
  dart.fn(constructor_name_clash_test.main, VoidTodynamic());
  constructor_name_clash_lib.global = 0;
  // Exports:
  exports.constructor_name_clash_test = constructor_name_clash_test;
  exports.constructor_name_clash_lib = constructor_name_clash_lib;
});
