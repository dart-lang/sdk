dart_library.library('language/issue10783_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10783_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10783_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10783_test.C = class C extends core.Object {
    foo(y) {
      return y;
    }
  };
  dart.setSignature(issue10783_test.C, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [core.int])})
  });
  issue10783_test.main = function() {
    for (let b of JSArrayOfListOfObject().of([JSArrayOfObject().of([false, 'pig'])])) {
      let c = null;
      if (dart.test(b[dartx.get](0))) c = new issue10783_test.C();
      expect$.Expect.throws(dart.fn(() => core.print(dart.dsend(c, 'foo', b[dartx.get](1))), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    }
  };
  dart.fn(issue10783_test.main, VoidTodynamic());
  // Exports:
  exports.issue10783_test = issue10783_test;
});
