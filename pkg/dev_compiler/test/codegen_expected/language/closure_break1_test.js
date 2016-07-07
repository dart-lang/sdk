dart_library.library('language/closure_break1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_break1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_break1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_break1_test.ClosureBreak1 = class ClosureBreak1 extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(closure_break1_test.ClosureBreak1, {
    constructors: () => ({new: dart.definiteFunctionType(closure_break1_test.ClosureBreak1, [core.int])})
  });
  closure_break1_test.ClosureBreak1Test = class ClosureBreak1Test extends core.Object {
    static testMain() {
      let o1 = new closure_break1_test.ClosureBreak1(3);
      let newstr = "abcdefgh";
      function foo() {
        o1.field = dart.notNull(o1.field) + 1;
        expect$.Expect.equals(8, newstr[dartx.length]);
      }
      dart.fn(foo, VoidTodynamic());
      let loop = true;
      L:
        while (loop) {
          let newstr1 = "abcd";
          let o2 = new closure_break1_test.ClosureBreak1(3);
          function foo1() {
            o2.field = dart.notNull(o2.field) + 1;
            expect$.Expect.equals(4, newstr1[dartx.length]);
          }
          dart.fn(foo1, VoidTodynamic());
          expect$.Expect.equals(4, newstr1[dartx.length]);
          while (loop) {
            let newint = 0;
            let o3 = new closure_break1_test.ClosureBreak1(3);
            function foo2() {
              o3.field = dart.notNull(o3.field) + 1;
              expect$.Expect.equals(0, newint);
            }
            dart.fn(foo2, VoidTodynamic());
            foo2();
            break L;
          }
        }
      foo();
      expect$.Expect.equals(4, o1.field);
    }
  };
  dart.setSignature(closure_break1_test.ClosureBreak1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  closure_break1_test.main = function() {
    closure_break1_test.ClosureBreak1Test.testMain();
  };
  dart.fn(closure_break1_test.main, VoidTodynamic());
  // Exports:
  exports.closure_break1_test = closure_break1_test;
});
