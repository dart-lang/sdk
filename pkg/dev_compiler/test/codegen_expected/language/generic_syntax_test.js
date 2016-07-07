dart_library.library('language/generic_syntax_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_syntax_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_syntax_test = Object.create(null);
  let GenericSyntaxTest = () => (GenericSyntaxTest = dart.constFn(generic_syntax_test.GenericSyntaxTest$()))();
  let A = () => (A = dart.constFn(generic_syntax_test.A$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_syntax_test.GenericSyntaxTest$ = dart.generic((B, C, D, E, F) => {
    let AOfB$C$D$E$F = () => (AOfB$C$D$E$F = dart.constFn(generic_syntax_test.A$(B, C, D, E, F)))();
    let AOfB$C$D$E$FTodynamic = () => (AOfB$C$D$E$FTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [AOfB$C$D$E$F()])))();
    class GenericSyntaxTest extends core.Object {
      new() {
      }
      foo(x1, x2, x3, x4, x5) {
        expect$.Expect.equals(true, x1);
        expect$.Expect.equals(3, x2);
        expect$.Expect.equals(4, x3);
        expect$.Expect.equals(5, x4);
        expect$.Expect.equals(false, x5);
      }
      bar(x) {
        expect$.Expect.equals(null, dart.dcall(x, null));
      }
      test() {
        let a = 1;
        let b = 2;
        let c = 3;
        let d = 4;
        let e = 5;
        let f = 6;
        let g = 7;
        let h = null;
        this.bar(dart.fn(g => h, AOfB$C$D$E$FTodynamic()));
        this.foo(a < b, c, d, e, f > g);
      }
      static testMain() {
        new generic_syntax_test.GenericSyntaxTest().test();
      }
    }
    dart.addTypeTests(GenericSyntaxTest);
    dart.setSignature(GenericSyntaxTest, {
      constructors: () => ({new: dart.definiteFunctionType(generic_syntax_test.GenericSyntaxTest$(B, C, D, E, F), [])}),
      methods: () => ({
        foo: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]),
        bar: dart.definiteFunctionType(dart.void, [dart.dynamic]),
        test: dart.definiteFunctionType(dart.dynamic, [])
      }),
      statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
      names: ['testMain']
    });
    return GenericSyntaxTest;
  });
  generic_syntax_test.GenericSyntaxTest = GenericSyntaxTest();
  generic_syntax_test.A$ = dart.generic((B, C, D, E, F) => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  generic_syntax_test.A = A();
  generic_syntax_test.main = function() {
    generic_syntax_test.GenericSyntaxTest.testMain();
  };
  dart.fn(generic_syntax_test.main, VoidTodynamic());
  // Exports:
  exports.generic_syntax_test = generic_syntax_test;
});
