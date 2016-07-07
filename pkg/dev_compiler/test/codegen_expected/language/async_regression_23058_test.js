dart_library.library('language/async_regression_23058_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_regression_23058_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_regression_23058_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_regression_23058_test.A = class A extends core.Object {
    new() {
      this.x = new async_regression_23058_test.B();
    }
    foo() {
      return dart.async((function*() {
        return dart.equals(this.x.foo, 2) ? 42 : this.x.foo;
      }).bind(this), dart.dynamic);
    }
  };
  dart.setSignature(async_regression_23058_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  async_regression_23058_test.B = class B extends core.Object {
    new() {
      this.x = 0;
    }
    get foo() {
      if (this.x == -1) {
        return 0;
      } else {
        let x = this.x;
        this.x = dart.notNull(x) + 1;
        return x;
      }
    }
  };
  async_regression_23058_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(new async_regression_23058_test.A().foo(), 'then', dart.fn(result => {
      expect$.Expect.equals(1, result);
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(async_regression_23058_test.main, VoidTodynamic());
  // Exports:
  exports.async_regression_23058_test = async_regression_23058_test;
});
