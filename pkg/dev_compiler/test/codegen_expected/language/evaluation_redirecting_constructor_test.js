dart_library.library('language/evaluation_redirecting_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__evaluation_redirecting_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const evaluation_redirecting_constructor_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  evaluation_redirecting_constructor_test.counter = 0;
  evaluation_redirecting_constructor_test.Bar = class Bar extends core.Object {
    new() {
      evaluation_redirecting_constructor_test.counter = dart.notNull(evaluation_redirecting_constructor_test.counter) + 1;
    }
  };
  dart.setSignature(evaluation_redirecting_constructor_test.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(evaluation_redirecting_constructor_test.Bar, [])})
  });
  const _bar = Symbol('_bar');
  evaluation_redirecting_constructor_test.A = class A extends core.Object {
    new() {
      A.prototype._.call(this);
    }
    _() {
      this[_bar] = new evaluation_redirecting_constructor_test.Bar();
      dart.fn(() => 42, VoidToint());
    }
  };
  dart.defineNamedConstructor(evaluation_redirecting_constructor_test.A, '_');
  dart.setSignature(evaluation_redirecting_constructor_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(evaluation_redirecting_constructor_test.A, []),
      _: dart.definiteFunctionType(evaluation_redirecting_constructor_test.A, [])
    })
  });
  evaluation_redirecting_constructor_test.main = function() {
    new evaluation_redirecting_constructor_test.A();
    expect$.Expect.equals(1, evaluation_redirecting_constructor_test.counter);
  };
  dart.fn(evaluation_redirecting_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.evaluation_redirecting_constructor_test = evaluation_redirecting_constructor_test;
});
