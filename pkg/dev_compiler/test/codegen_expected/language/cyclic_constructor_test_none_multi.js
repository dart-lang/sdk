dart_library.library('language/cyclic_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__cyclic_constructor_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cyclic_constructor_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_constructor_test_none_multi.A = class A extends core.Object {
    a() {
      A.prototype.b.call(this);
    }
    b() {
    }
    c() {
      A.prototype.b.call(this);
    }
  };
  dart.defineNamedConstructor(cyclic_constructor_test_none_multi.A, 'a');
  dart.defineNamedConstructor(cyclic_constructor_test_none_multi.A, 'b');
  dart.defineNamedConstructor(cyclic_constructor_test_none_multi.A, 'c');
  dart.setSignature(cyclic_constructor_test_none_multi.A, {
    constructors: () => ({
      a: dart.definiteFunctionType(cyclic_constructor_test_none_multi.A, []),
      b: dart.definiteFunctionType(cyclic_constructor_test_none_multi.A, []),
      c: dart.definiteFunctionType(cyclic_constructor_test_none_multi.A, [])
    })
  });
  cyclic_constructor_test_none_multi.main = function() {
    new cyclic_constructor_test_none_multi.A.a();
    new cyclic_constructor_test_none_multi.A.b();
    new cyclic_constructor_test_none_multi.A.c();
  };
  dart.fn(cyclic_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_constructor_test_none_multi = cyclic_constructor_test_none_multi;
});
