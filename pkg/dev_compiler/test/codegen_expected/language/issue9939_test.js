dart_library.library('language/issue9939_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue9939_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue9939_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(issue9939_test, {
    get globalVar() {
      return JSArrayOfint().of([1, 2]);
    },
    set globalVar(_) {}
  });
  issue9939_test.A = class A extends core.Object {
    new(field1, field2) {
      this.field1 = field1;
      this.field2 = field2;
      this.field3 = null;
      let entered = false;
      for (let a of core.Iterable._check(this.field1)) {
        try {
          entered = true;
          core.print(this.field2);
          core.print(this.field2);
        } catch (e) {
          dart.throw(e);
        }

      }
      expect$.Expect.isTrue(entered);
      expect$.Expect.equals(issue9939_test.globalVar, this.field1);
    }
  };
  dart.setSignature(issue9939_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(issue9939_test.A, [dart.dynamic, dart.dynamic])})
  });
  issue9939_test.main = function() {
    new issue9939_test.A(issue9939_test.globalVar, null);
  };
  dart.fn(issue9939_test.main, VoidTodynamic());
  // Exports:
  exports.issue9939_test = issue9939_test;
});
