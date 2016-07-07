dart_library.library('language/f_bounded_equality_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__f_bounded_equality_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const f_bounded_equality_test = Object.create(null);
  let Magnitude = () => (Magnitude = dart.constFn(f_bounded_equality_test.Magnitude$()))();
  let FBound = () => (FBound = dart.constFn(f_bounded_equality_test.FBound$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  f_bounded_equality_test.Magnitude$ = dart.generic(T => {
    class Magnitude extends core.Object {
      get t() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Magnitude);
    return Magnitude;
  });
  f_bounded_equality_test.Magnitude = Magnitude();
  f_bounded_equality_test.Real = class Real extends f_bounded_equality_test.Magnitude {};
  dart.setBaseClass(f_bounded_equality_test.Real, f_bounded_equality_test.Magnitude$(f_bounded_equality_test.Real));
  dart.addSimpleTypeTests(f_bounded_equality_test.Real);
  f_bounded_equality_test.FBound$ = dart.generic(F => {
    class FBound extends core.Object {
      get f() {
        return dart.wrapType(F);
      }
    }
    dart.addTypeTests(FBound);
    return FBound;
  });
  f_bounded_equality_test.FBound = FBound();
  f_bounded_equality_test.Bar = class Bar extends f_bounded_equality_test.FBound {};
  dart.setBaseClass(f_bounded_equality_test.Bar, f_bounded_equality_test.FBound$(f_bounded_equality_test.Bar));
  dart.addSimpleTypeTests(f_bounded_equality_test.Bar);
  f_bounded_equality_test.main = function() {
    let r = new f_bounded_equality_test.Real();
    expect$.Expect.equals(r.runtimeType, dart.wrapType(f_bounded_equality_test.Real));
    expect$.Expect.equals(r.t, dart.wrapType(f_bounded_equality_test.Real));
    expect$.Expect.equals(r.runtimeType, r.t);
    let b = new f_bounded_equality_test.Bar();
    expect$.Expect.equals(b.runtimeType, dart.wrapType(f_bounded_equality_test.Bar));
    expect$.Expect.equals(b.f, dart.wrapType(f_bounded_equality_test.Bar));
    expect$.Expect.equals(b.runtimeType, b.f);
  };
  dart.fn(f_bounded_equality_test.main, VoidTodynamic());
  // Exports:
  exports.f_bounded_equality_test = f_bounded_equality_test;
});
