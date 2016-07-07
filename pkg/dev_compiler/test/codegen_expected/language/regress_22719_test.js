dart_library.library('language/regress_22719_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22719_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22719_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_22719_test.A = class A extends core.Object {};
  regress_22719_test.B = class B extends dart.mixin(core.Object, collection.IterableMixin$(core.int)) {};
  regress_22719_test.C = class C extends dart.mixin(regress_22719_test.A, collection.IterableMixin$(core.int)) {
    new() {
      this.list = JSArrayOfint().of([1, 2, 3, 4, 5]);
    }
    get iterator() {
      return this.list[dartx.iterator];
    }
  };
  regress_22719_test.C[dart.implements] = () => [regress_22719_test.B];
  dart.setSignature(regress_22719_test.C, {});
  dart.defineExtensionMembers(regress_22719_test.C, ['iterator']);
  regress_22719_test.D = class D extends regress_22719_test.C {
    new() {
      super.new();
    }
  };
  regress_22719_test.main = function() {
    let d = new regress_22719_test.D();
    let expected = 1;
    for (let i of d) {
      expect$.Expect.equals(expected, i);
      expected = expected + 1;
    }
  };
  dart.fn(regress_22719_test.main, VoidTovoid());
  // Exports:
  exports.regress_22719_test = regress_22719_test;
});
