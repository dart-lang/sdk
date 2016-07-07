dart_library.library('language/closure_break_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_break_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_break_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_break_test.ClosureBreak = class ClosureBreak extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(closure_break_test.ClosureBreak, {
    constructors: () => ({new: dart.definiteFunctionType(closure_break_test.ClosureBreak, [core.int])})
  });
  closure_break_test.ClosureBreakTest = class ClosureBreakTest extends core.Object {
    static testMain() {
      let o1 = new closure_break_test.ClosureBreak(3);
      let newstr = "abcdefgh";
      function foo() {
        o1.field = dart.notNull(o1.field) + 1;
        expect$.Expect.equals(8, newstr[dartx.length]);
      }
      dart.fn(foo, VoidTodynamic());
      let loop = true;
      L1:
        while (loop) {
          let newstr1 = "abcd";
          let o2 = new closure_break_test.ClosureBreak(3);
          function foo1() {
            o2.field = dart.notNull(o2.field) + 1;
            expect$.Expect.equals(4, newstr1[dartx.length]);
          }
          dart.fn(foo1, VoidTodynamic());
          expect$.Expect.equals(4, newstr1[dartx.length]);
          L2:
            while (loop) {
              let newint = 0;
              let o3 = new closure_break_test.ClosureBreak(3);
              function foo2() {
                o3.field = dart.notNull(o3.field) + 1;
                expect$.Expect.equals(0, newint);
              }
              dart.fn(foo2, VoidTodynamic());
              foo2();
              break L2;
            }
          foo1();
          expect$.Expect.equals(4, newstr1[dartx.length]);
          break L1;
        }
      foo();
      expect$.Expect.equals(4, o1.field);
    }
  };
  dart.setSignature(closure_break_test.ClosureBreakTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  closure_break_test.main = function() {
    closure_break_test.ClosureBreakTest.testMain();
  };
  dart.fn(closure_break_test.main, VoidTodynamic());
  // Exports:
  exports.closure_break_test = closure_break_test;
});
