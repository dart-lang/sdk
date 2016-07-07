dart_library.library('language/closures_initializer_test', null, /* Imports */[
  'dart_sdk'
], function load__closures_initializer_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const closures_initializer_test = Object.create(null);
  let A = () => (A = dart.constFn(closures_initializer_test.A$()))();
  let B = () => (B = dart.constFn(closures_initializer_test.B$()))();
  let AOfint = () => (AOfint = dart.constFn(closures_initializer_test.A$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(closures_initializer_test.A$(core.String)))();
  let BOfint = () => (BOfint = dart.constFn(closures_initializer_test.B$(core.int)))();
  let VoidToType = () => (VoidToType = dart.constFn(dart.definiteFunctionType(core.Type, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closures_initializer_test.A$ = dart.generic(T => {
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    let VoidToListOfT = () => (VoidToListOfT = dart.constFn(dart.definiteFunctionType(ListOfT(), [])))();
    class A extends core.Object {
      new() {
        this.t = dart.fn(() => ListOfT().new(), VoidToListOfT());
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(closures_initializer_test.A$(T), [])})
    });
    return A;
  });
  closures_initializer_test.A = A();
  closures_initializer_test.B$ = dart.generic(T => {
    class B extends core.Object {
      new() {
        this.t = dart.fn(() => dart.wrapType(T), VoidToType());
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      constructors: () => ({new: dart.definiteFunctionType(closures_initializer_test.B$(T), [])})
    });
    return B;
  });
  closures_initializer_test.B = B();
  closures_initializer_test.expect = function(result, expected) {
    if (!dart.equals(result, expected)) {
      dart.throw(dart.str`Expected ${expected}, got ${result}`);
    }
  };
  dart.fn(closures_initializer_test.expect, dynamicAnddynamicTodynamic());
  closures_initializer_test.main = function() {
    closures_initializer_test.expect(ListOfint().is(dart.dsend(new (AOfint())(), 't')), true);
    closures_initializer_test.expect(ListOfint().is(dart.dsend(new (AOfString())(), 't')), false);
    closures_initializer_test.expect(core.Type.is(dart.dsend(new (BOfint())(), 't')), true);
    closures_initializer_test.expect(dart.dsend(new (BOfint())(), 't'), dart.wrapType(core.int));
  };
  dart.fn(closures_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.closures_initializer_test = closures_initializer_test;
});
