dart_library.library('language/first_class_types_constants_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__first_class_types_constants_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const first_class_types_constants_test = Object.create(null);
  let C = () => (C = dart.constFn(first_class_types_constants_test.C$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  first_class_types_constants_test.C$ = dart.generic(T => {
    class C extends core.Object {
      new(t) {
        this.t = t;
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      constructors: () => ({new: dart.definiteFunctionType(first_class_types_constants_test.C$(T), [T])})
    });
    return C;
  });
  first_class_types_constants_test.C = C();
  first_class_types_constants_test.Fun = dart.typedef('Fun', () => dart.functionType(core.int, [dart.dynamic, dart.dynamic]));
  first_class_types_constants_test.c0 = dart.wrapType(first_class_types_constants_test.C);
  first_class_types_constants_test.c1 = dart.const(new first_class_types_constants_test.C(dart.wrapType(first_class_types_constants_test.C)));
  first_class_types_constants_test.c2 = dart.wrapType(first_class_types_constants_test.Fun);
  first_class_types_constants_test.c3 = dart.const(new first_class_types_constants_test.C(dart.wrapType(first_class_types_constants_test.Fun)));
  first_class_types_constants_test.main = function() {
    expect$.Expect.identical(dart.wrapType(first_class_types_constants_test.C), dart.wrapType(first_class_types_constants_test.C));
    expect$.Expect.identical(dart.wrapType(first_class_types_constants_test.C), first_class_types_constants_test.c0);
    expect$.Expect.identical(first_class_types_constants_test.c1, first_class_types_constants_test.c1);
    expect$.Expect.notEquals(first_class_types_constants_test.c0, first_class_types_constants_test.c1);
    expect$.Expect.notEquals(first_class_types_constants_test.c1, first_class_types_constants_test.c2);
    expect$.Expect.identical(first_class_types_constants_test.c1.t, first_class_types_constants_test.c0);
    expect$.Expect.notEquals(dart.wrapType(first_class_types_constants_test.C), dart.wrapType(first_class_types_constants_test.Fun));
    expect$.Expect.identical(dart.wrapType(first_class_types_constants_test.Fun), dart.wrapType(first_class_types_constants_test.Fun));
    expect$.Expect.identical(dart.wrapType(first_class_types_constants_test.Fun), first_class_types_constants_test.c2);
    expect$.Expect.identical(first_class_types_constants_test.c3.t, first_class_types_constants_test.c2);
  };
  dart.fn(first_class_types_constants_test.main, VoidTodynamic());
  // Exports:
  exports.first_class_types_constants_test = first_class_types_constants_test;
});
