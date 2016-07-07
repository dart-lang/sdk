dart_library.library('language/regress_23650_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_23650_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_23650_test = Object.create(null);
  let C = () => (C = dart.constFn(regress_23650_test.C$()))();
  let COfint = () => (COfint = dart.constFn(regress_23650_test.C$(core.int)))();
  let COfString = () => (COfString = dart.constFn(regress_23650_test.C$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_23650_test.C$ = dart.generic(T => {
    let COfT = () => (COfT = dart.constFn(regress_23650_test.C$(T)))();
    class C extends core.Object {
      foo() {
      }
      static new() {
        try {
          return new (COfT()).foo();
        } finally {
        }
      }
    }
    dart.addTypeTests(C);
    dart.defineNamedConstructor(C, 'foo');
    dart.setSignature(C, {
      constructors: () => ({
        foo: dart.definiteFunctionType(regress_23650_test.C$(T), []),
        new: dart.definiteFunctionType(regress_23650_test.C$(T), [])
      })
    });
    return C;
  });
  regress_23650_test.C = C();
  regress_23650_test.main = function() {
    let c = COfint().new();
    expect$.Expect.isTrue(COfint().is(c));
    expect$.Expect.isFalse(COfString().is(c));
  };
  dart.fn(regress_23650_test.main, VoidTodynamic());
  // Exports:
  exports.regress_23650_test = regress_23650_test;
});
