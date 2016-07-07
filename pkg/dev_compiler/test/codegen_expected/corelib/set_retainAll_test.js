dart_library.library('corelib/set_retainAll_test', null, /* Imports */[
  'dart_sdk'
], function load__set_retainAll_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const set_retainAll_test = Object.create(null);
  let SetOfB = () => (SetOfB = dart.constFn(core.Set$(set_retainAll_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(set_retainAll_test.B)))();
  let JSArrayOfSetOfB = () => (JSArrayOfSetOfB = dart.constFn(_interceptors.JSArray$(SetOfB())))();
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(set_retainAll_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  set_retainAll_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(set_retainAll_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(set_retainAll_test.A, [])})
  });
  set_retainAll_test.B = class B extends set_retainAll_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(set_retainAll_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(set_retainAll_test.B, [])})
  });
  let const$;
  let const$0;
  set_retainAll_test.main = function() {
    let set1 = SetOfB().new();
    set1.add(const$ || (const$ = dart.const(new set_retainAll_test.B())));
    let set2 = SetOfB().new();
    let list = JSArrayOfB().of([const$0 || (const$0 = dart.const(new set_retainAll_test.B()))]);
    let set3 = list[dartx.toSet]();
    let sets = JSArrayOfSetOfB().of([set1, set2, set3]);
    for (let setToTest of sets) {
      setToTest.retainAll(JSArrayOfA().of([new set_retainAll_test.A()]));
    }
  };
  dart.fn(set_retainAll_test.main, VoidTodynamic());
  // Exports:
  exports.set_retainAll_test = set_retainAll_test;
});
