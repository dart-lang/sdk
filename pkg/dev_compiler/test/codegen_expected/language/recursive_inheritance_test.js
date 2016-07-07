dart_library.library('language/recursive_inheritance_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__recursive_inheritance_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const recursive_inheritance_test = Object.create(null);
  let Comparable = () => (Comparable = dart.constFn(recursive_inheritance_test.Comparable$()))();
  let MI = () => (MI = dart.constFn(recursive_inheritance_test.MI$()))();
  let PMI = () => (PMI = dart.constFn(recursive_inheritance_test.PMI$()))();
  let MIOfMI = () => (MIOfMI = dart.constFn(recursive_inheritance_test.MI$(recursive_inheritance_test.MI)))();
  let PMIOfComparable = () => (PMIOfComparable = dart.constFn(recursive_inheritance_test.PMI$(recursive_inheritance_test.Comparable)))();
  let MIOfPMIOfComparable = () => (MIOfPMIOfComparable = dart.constFn(recursive_inheritance_test.MI$(PMIOfComparable())))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  recursive_inheritance_test.Comparable$ = dart.generic(T => {
    class Comparable extends core.Object {}
    dart.addTypeTests(Comparable);
    return Comparable;
  });
  recursive_inheritance_test.Comparable = Comparable();
  recursive_inheritance_test.MI$ = dart.generic(T => {
    class MI extends core.Object {}
    dart.addTypeTests(MI);
    return MI;
  });
  recursive_inheritance_test.MI = MI();
  recursive_inheritance_test.PMI$ = dart.generic(T => {
    class PMI extends recursive_inheritance_test.MI {}
    dart.setBaseClass(PMI, recursive_inheritance_test.MI$(PMI));
    return PMI;
  });
  recursive_inheritance_test.PMI = PMI();
  recursive_inheritance_test.main = function() {
    let a = new (MIOfMI())();
    let b = new (PMIOfComparable())();
    a = b;
    expect$.Expect.isTrue(MIOfMI().is(a));
    expect$.Expect.isTrue(PMIOfComparable().is(b));
    expect$.Expect.isTrue(MIOfMI().is(b));
    expect$.Expect.isTrue(MIOfPMIOfComparable().is(b));
  };
  dart.fn(recursive_inheritance_test.main, VoidTovoid());
  // Exports:
  exports.recursive_inheritance_test = recursive_inheritance_test;
});
