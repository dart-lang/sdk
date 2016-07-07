dart_library.library('language/abstract_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__abstract_syntax_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const abstract_syntax_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  abstract_syntax_test_none_multi.main = function() {
    let b = new abstract_syntax_test_none_multi.B();
    expect$.Expect.equals(42, b.foo());
  };
  dart.fn(abstract_syntax_test_none_multi.main, VoidTodynamic());
  abstract_syntax_test_none_multi.A = class A extends core.Object {};
  abstract_syntax_test_none_multi.B = class B extends abstract_syntax_test_none_multi.A {
    foo() {
      return 42;
    }
    bar() {
      return 87;
    }
  };
  dart.setSignature(abstract_syntax_test_none_multi.B, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  // Exports:
  exports.abstract_syntax_test_none_multi = abstract_syntax_test_none_multi;
});
