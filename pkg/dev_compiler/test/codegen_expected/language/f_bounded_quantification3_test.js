dart_library.library('language/f_bounded_quantification3_test', null, /* Imports */[
  'dart_sdk'
], function load__f_bounded_quantification3_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const f_bounded_quantification3_test = Object.create(null);
  let FBound1 = () => (FBound1 = dart.constFn(f_bounded_quantification3_test.FBound1$()))();
  let FBound2 = () => (FBound2 = dart.constFn(f_bounded_quantification3_test.FBound2$()))();
  let FBound1OfBar$Baz = () => (FBound1OfBar$Baz = dart.constFn(f_bounded_quantification3_test.FBound1$(f_bounded_quantification3_test.Bar, f_bounded_quantification3_test.Baz)))();
  let FBound2OfBar$Baz = () => (FBound2OfBar$Baz = dart.constFn(f_bounded_quantification3_test.FBound2$(f_bounded_quantification3_test.Bar, f_bounded_quantification3_test.Baz)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  f_bounded_quantification3_test.FBound1$ = dart.generic((F1, F2) => {
    let FBound1OfF1$F2 = () => (FBound1OfF1$F2 = dart.constFn(f_bounded_quantification3_test.FBound1$(F1, F2)))();
    let FBound2OfF1$F2 = () => (FBound2OfF1$F2 = dart.constFn(f_bounded_quantification3_test.FBound2$(F1, F2)))();
    class FBound1 extends core.Object {
      Test() {
        new (FBound1OfF1$F2())();
        new (FBound2OfF1$F2())();
      }
    }
    dart.addTypeTests(FBound1);
    dart.setSignature(FBound1, {
      methods: () => ({Test: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return FBound1;
  });
  f_bounded_quantification3_test.FBound1 = FBound1();
  f_bounded_quantification3_test.FBound2$ = dart.generic((F1, F2) => {
    let FBound1OfF1$F2 = () => (FBound1OfF1$F2 = dart.constFn(f_bounded_quantification3_test.FBound1$(F1, F2)))();
    let FBound2OfF1$F2 = () => (FBound2OfF1$F2 = dart.constFn(f_bounded_quantification3_test.FBound2$(F1, F2)))();
    class FBound2 extends core.Object {
      Test() {
        new (FBound1OfF1$F2())();
        new (FBound2OfF1$F2())();
      }
    }
    dart.addTypeTests(FBound2);
    dart.setSignature(FBound2, {
      methods: () => ({Test: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return FBound2;
  });
  f_bounded_quantification3_test.FBound2 = FBound2();
  f_bounded_quantification3_test.Bar = class Bar extends f_bounded_quantification3_test.FBound1 {};
  dart.setBaseClass(f_bounded_quantification3_test.Bar, f_bounded_quantification3_test.FBound1$(f_bounded_quantification3_test.Bar, f_bounded_quantification3_test.Baz));
  dart.addSimpleTypeTests(f_bounded_quantification3_test.Bar);
  f_bounded_quantification3_test.Baz = class Baz extends f_bounded_quantification3_test.FBound2 {};
  dart.setBaseClass(f_bounded_quantification3_test.Baz, f_bounded_quantification3_test.FBound2$(f_bounded_quantification3_test.Bar, f_bounded_quantification3_test.Baz));
  dart.addSimpleTypeTests(f_bounded_quantification3_test.Baz);
  f_bounded_quantification3_test.main = function() {
    new (FBound1OfBar$Baz())().Test();
    new (FBound2OfBar$Baz())().Test();
  };
  dart.fn(f_bounded_quantification3_test.main, VoidTodynamic());
  // Exports:
  exports.f_bounded_quantification3_test = f_bounded_quantification3_test;
});
