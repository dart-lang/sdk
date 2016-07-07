dart_library.library('corelib/error_stack_trace1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__error_stack_trace1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const error_stack_trace1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  error_stack_trace1_test.A = class A extends core.Object {
    static Aa() {
      return error_stack_trace1_test.A.Ab();
    }
    static Ab() {
      return error_stack_trace1_test.A.Ac();
    }
    static Ac() {
      return dart.throw("abc");
    }
  };
  dart.setSignature(error_stack_trace1_test.A, {
    statics: () => ({
      Aa: dart.definiteFunctionType(dart.dynamic, []),
      Ab: dart.definiteFunctionType(dart.dynamic, []),
      Ac: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['Aa', 'Ab', 'Ac']
  });
  error_stack_trace1_test.B = class B extends core.Object {
    static Ba() {
      return error_stack_trace1_test.B.Bb();
    }
    static Bb() {
      return error_stack_trace1_test.B.Bc();
    }
    static Bc() {
      try {
        error_stack_trace1_test.A.Aa();
      } catch (e) {
        let trace = dart.dload(e, 'stackTrace');
      }

    }
  };
  dart.setSignature(error_stack_trace1_test.B, {
    statics: () => ({
      Ba: dart.definiteFunctionType(dart.dynamic, []),
      Bb: dart.definiteFunctionType(dart.dynamic, []),
      Bc: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['Ba', 'Bb', 'Bc']
  });
  error_stack_trace1_test.main = function() {
    let hasThrown = false;
    try {
      error_stack_trace1_test.B.Ba();
    } catch (e) {
      hasThrown = true;
      let trace = dart.toString(dart.dload(e, 'stackTrace'));
      core.print(trace);
      expect$.Expect.isTrue(trace[dartx.contains]("Bc"));
      expect$.Expect.isTrue(trace[dartx.contains]("Bb"));
      expect$.Expect.isTrue(trace[dartx.contains]("Ba"));
      expect$.Expect.isTrue(trace[dartx.contains]("main"));
    }

    expect$.Expect.isTrue(hasThrown);
  };
  dart.fn(error_stack_trace1_test.main, VoidTodynamic());
  // Exports:
  exports.error_stack_trace1_test = error_stack_trace1_test;
});
