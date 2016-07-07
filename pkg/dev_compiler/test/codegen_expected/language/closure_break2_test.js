dart_library.library('language/closure_break2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_break2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_break2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_break2_test.ClosureBreak2 = class ClosureBreak2 extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(closure_break2_test.ClosureBreak2, {
    constructors: () => ({new: dart.definiteFunctionType(closure_break2_test.ClosureBreak2, [core.int])})
  });
  closure_break2_test.ClosureBreak2Test = class ClosureBreak2Test extends core.Object {
    static testMain() {
      let o1 = new closure_break2_test.ClosureBreak2(3);
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
          expect$.Expect.equals(4, newstr1[dartx.length]);
          while (loop) {
            let newint = 0;
            expect$.Expect.equals(4, newstr1[dartx.length]);
            break L;
          }
        }
      foo();
      expect$.Expect.equals(4, o1.field);
    }
  };
  dart.setSignature(closure_break2_test.ClosureBreak2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  closure_break2_test.main = function() {
    closure_break2_test.ClosureBreak2Test.testMain();
  };
  dart.fn(closure_break2_test.main, VoidTodynamic());
  // Exports:
  exports.closure_break2_test = closure_break2_test;
});
