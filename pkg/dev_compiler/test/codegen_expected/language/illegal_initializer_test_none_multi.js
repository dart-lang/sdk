dart_library.library('language/illegal_initializer_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__illegal_initializer_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const illegal_initializer_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  illegal_initializer_test_none_multi.A = class A extends core.Object {
    new() {
    }
    foo() {
    }
  };
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.A, 'foo');
  dart.setSignature(illegal_initializer_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(illegal_initializer_test_none_multi.A, []),
      foo: dart.definiteFunctionType(illegal_initializer_test_none_multi.A, [])
    })
  });
  illegal_initializer_test_none_multi.B = class B extends illegal_initializer_test_none_multi.A {
    c1() {
      super.foo();
    }
    foo() {
      super.new();
    }
    c2() {
      B.prototype.foo.call(this);
    }
    c3() {
      super.new();
    }
    new() {
      super.new();
    }
    c4() {
      B.prototype.new.call(this);
    }
  };
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.B, 'c1');
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.B, 'foo');
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.B, 'c2');
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.B, 'c3');
  dart.defineNamedConstructor(illegal_initializer_test_none_multi.B, 'c4');
  dart.setSignature(illegal_initializer_test_none_multi.B, {
    constructors: () => ({
      c1: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, []),
      foo: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, []),
      c2: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, []),
      c3: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, []),
      new: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, []),
      c4: dart.definiteFunctionType(illegal_initializer_test_none_multi.B, [])
    })
  });
  illegal_initializer_test_none_multi.main = function() {
    new illegal_initializer_test_none_multi.B.c1();
    new illegal_initializer_test_none_multi.B.c2();
    new illegal_initializer_test_none_multi.B.c3();
    new illegal_initializer_test_none_multi.B.c4();
  };
  dart.fn(illegal_initializer_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.illegal_initializer_test_none_multi = illegal_initializer_test_none_multi;
});
