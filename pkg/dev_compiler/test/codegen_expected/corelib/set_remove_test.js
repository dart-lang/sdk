dart_library.library('corelib/set_remove_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__set_remove_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const set_remove_test = Object.create(null);
  let SetOfB = () => (SetOfB = dart.constFn(core.Set$(set_remove_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(set_remove_test.B)))();
  let JSArrayOfSetOfB = () => (JSArrayOfSetOfB = dart.constFn(_interceptors.JSArray$(SetOfB())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  set_remove_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(set_remove_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(set_remove_test.A, [])})
  });
  set_remove_test.B = class B extends set_remove_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(set_remove_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(set_remove_test.B, [])})
  });
  let const$;
  let const$0;
  set_remove_test.main = function() {
    let set1 = SetOfB().new();
    set1.add(const$ || (const$ = dart.const(new set_remove_test.B())));
    let set2 = SetOfB().new();
    let list = JSArrayOfB().of([const$0 || (const$0 = dart.const(new set_remove_test.B()))]);
    let set3 = list[dartx.toSet]();
    let sets = JSArrayOfSetOfB().of([set1, set2, set3]);
    for (let setToTest of sets) {
      expect$.Expect.isFalse(setToTest.remove(new set_remove_test.A()));
    }
  };
  dart.fn(set_remove_test.main, VoidTodynamic());
  // Exports:
  exports.set_remove_test = set_remove_test;
});
