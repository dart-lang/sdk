dart_library.library('language/not_enough_positional_arguments_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__not_enough_positional_arguments_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const not_enough_positional_arguments_test_none_multi = Object.create(null);
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let dynamic__Todynamic$ = () => (dynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {b: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  not_enough_positional_arguments_test_none_multi.foo = function(a, b) {
    if (b === void 0) b = null;
  };
  dart.fn(not_enough_positional_arguments_test_none_multi.foo, dynamic__Todynamic());
  not_enough_positional_arguments_test_none_multi.bar = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
  };
  dart.fn(not_enough_positional_arguments_test_none_multi.bar, dynamic__Todynamic$());
  not_enough_positional_arguments_test_none_multi.A = class A extends core.Object {
    new() {
    }
    test(a, b) {
      if (b === void 0) b = null;
    }
  };
  dart.defineNamedConstructor(not_enough_positional_arguments_test_none_multi.A, 'test');
  dart.setSignature(not_enough_positional_arguments_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.A, []),
      test: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.A, [dart.dynamic], [dart.dynamic])
    })
  });
  not_enough_positional_arguments_test_none_multi.B = class B extends core.Object {
    new() {
    }
  };
  dart.setSignature(not_enough_positional_arguments_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.B, [])})
  });
  not_enough_positional_arguments_test_none_multi.C = class C extends not_enough_positional_arguments_test_none_multi.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(not_enough_positional_arguments_test_none_multi.C, {
    constructors: () => ({new: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.C, [])})
  });
  not_enough_positional_arguments_test_none_multi.D = class D extends core.Object {
    new() {
    }
    test(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
    }
  };
  dart.defineNamedConstructor(not_enough_positional_arguments_test_none_multi.D, 'test');
  dart.setSignature(not_enough_positional_arguments_test_none_multi.D, {
    constructors: () => ({
      new: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.D, []),
      test: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.D, [dart.dynamic], {b: dart.dynamic})
    })
  });
  not_enough_positional_arguments_test_none_multi.E = class E extends not_enough_positional_arguments_test_none_multi.D {
    new() {
      super.new();
    }
  };
  dart.setSignature(not_enough_positional_arguments_test_none_multi.E, {
    constructors: () => ({new: dart.definiteFunctionType(not_enough_positional_arguments_test_none_multi.E, [])})
  });
  not_enough_positional_arguments_test_none_multi.main = function() {
    new not_enough_positional_arguments_test_none_multi.B();
    new not_enough_positional_arguments_test_none_multi.C();
    new not_enough_positional_arguments_test_none_multi.E();
  };
  dart.fn(not_enough_positional_arguments_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.not_enough_positional_arguments_test_none_multi = not_enough_positional_arguments_test_none_multi;
});
