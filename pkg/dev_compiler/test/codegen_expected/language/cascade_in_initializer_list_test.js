dart_library.library('language/cascade_in_initializer_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade_in_initializer_list_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade_in_initializer_list_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade_in_initializer_list_test.A = class A extends core.Object {
    foo() {}
    bar() {}
  };
  dart.setSignature(cascade_in_initializer_list_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  cascade_in_initializer_list_test.B = class B extends core.Object {
    new(a) {
      this.x = ((() => {
        dart.dsend(a, 'foo');
        dart.dsend(a, 'bar');
        return a;
      })());
      this.y = ((() => {
        dart.dsend(a, 'foo');
        dart.dsend(a, 'bar');
        return a;
      })());
    }
  };
  dart.setSignature(cascade_in_initializer_list_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(cascade_in_initializer_list_test.B, [dart.dynamic])})
  });
  cascade_in_initializer_list_test.main = function() {
    let a = new cascade_in_initializer_list_test.A(), b = new cascade_in_initializer_list_test.B(a);
    expect$.Expect.equals(a, b.x);
    expect$.Expect.equals(a, b.y);
  };
  dart.fn(cascade_in_initializer_list_test.main, VoidTodynamic());
  // Exports:
  exports.cascade_in_initializer_list_test = cascade_in_initializer_list_test;
});
