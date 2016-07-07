dart_library.library('corelib/set_removeAll_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__set_removeAll_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const set_removeAll_test = Object.create(null);
  let SetOfB = () => (SetOfB = dart.constFn(core.Set$(set_removeAll_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(set_removeAll_test.B)))();
  let JSArrayOfSetOfB = () => (JSArrayOfSetOfB = dart.constFn(_interceptors.JSArray$(SetOfB())))();
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(set_removeAll_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  set_removeAll_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(set_removeAll_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(set_removeAll_test.A, [])})
  });
  set_removeAll_test.B = class B extends set_removeAll_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(set_removeAll_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(set_removeAll_test.B, [])})
  });
  let const$;
  let const$0;
  set_removeAll_test.main = function() {
    let set1 = SetOfB().new();
    set1.add(const$ || (const$ = dart.const(new set_removeAll_test.B())));
    let set2 = SetOfB().new();
    let list = JSArrayOfB().of([const$0 || (const$0 = dart.const(new set_removeAll_test.B()))]);
    let set3 = list[dartx.toSet]();
    let sets = JSArrayOfSetOfB().of([set1, set2, set3]);
    for (let setToTest of sets) {
      expect$.Expect.isNull(setToTest.removeAll(JSArrayOfA().of([new set_removeAll_test.A()])));
    }
  };
  dart.fn(set_removeAll_test.main, VoidTodynamic());
  // Exports:
  exports.set_removeAll_test = set_removeAll_test;
});
