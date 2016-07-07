dart_library.library('language/assign_to_type_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__assign_to_type_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const assign_to_type_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(assign_to_type_test_none_multi.C$()))();
  let COfD = () => (COfD = dart.constFn(assign_to_type_test_none_multi.C$(assign_to_type_test_none_multi.D)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  assign_to_type_test_none_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(assign_to_type_test_none_multi.noMethod, dynamicTodynamic());
  assign_to_type_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {
      f() {}
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({f: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return C;
  });
  assign_to_type_test_none_multi.C = C();
  assign_to_type_test_none_multi.D = class D extends core.Object {};
  assign_to_type_test_none_multi.E = class E extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "E.e0"
      }[this.index];
    }
  };
  assign_to_type_test_none_multi.E.e0 = dart.const(new assign_to_type_test_none_multi.E(0));
  assign_to_type_test_none_multi.E.values = dart.constList([assign_to_type_test_none_multi.E.e0], assign_to_type_test_none_multi.E);
  assign_to_type_test_none_multi.F = dart.typedef('F', () => dart.functionType(dart.void, []));
  assign_to_type_test_none_multi.main = function() {
    new (COfD())().f();
  };
  dart.fn(assign_to_type_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.assign_to_type_test_none_multi = assign_to_type_test_none_multi;
});
