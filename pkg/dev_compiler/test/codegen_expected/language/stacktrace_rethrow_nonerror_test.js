dart_library.library('language/stacktrace_rethrow_nonerror_test', null, /* Imports */[
  'dart_sdk'
], function load__stacktrace_rethrow_nonerror_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const stacktrace_rethrow_nonerror_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  stacktrace_rethrow_nonerror_test.NotASubclassOfError = class NotASubclassOfError extends core.Object {};
  stacktrace_rethrow_nonerror_test.fail = function() {
    return dart.throw("Fail");
  };
  dart.fn(stacktrace_rethrow_nonerror_test.fail, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.aa1 = function() {
    try {
      stacktrace_rethrow_nonerror_test.bb1();
      stacktrace_rethrow_nonerror_test.fail();
    } catch (exception) {
      let stacktrace = dart.stackTrace(exception);
      stacktrace_rethrow_nonerror_test.expectTrace(JSArrayOfString().of(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.aa1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.bb1 = function() {
    return stacktrace_rethrow_nonerror_test.cc1();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.bb1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.cc1 = function() {
    try {
      stacktrace_rethrow_nonerror_test.dd1();
    } catch (e$) {
      if (core.String.is(e$)) {
        let e = e$;
        stacktrace_rethrow_nonerror_test.fail();
      } else if (core.int.is(e$)) {
        let e = e$;
        stacktrace_rethrow_nonerror_test.fail();
      } else
        throw e$;
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.cc1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.dd1 = function() {
    return stacktrace_rethrow_nonerror_test.ee1();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.dd1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ee1 = function() {
    try {
      stacktrace_rethrow_nonerror_test.ff1();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.ee1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ff1 = function() {
    return stacktrace_rethrow_nonerror_test.gg1();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.ff1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.gg1 = function() {
    return dart.throw(new stacktrace_rethrow_nonerror_test.NotASubclassOfError());
  };
  dart.fn(stacktrace_rethrow_nonerror_test.gg1, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.aa2 = function() {
    try {
      stacktrace_rethrow_nonerror_test.bb2();
      stacktrace_rethrow_nonerror_test.fail();
    } catch (exception) {
      let stacktrace = dart.stackTrace(exception);
      stacktrace_rethrow_nonerror_test.expectTrace(JSArrayOfString().of(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.aa2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.bb2 = function() {
    return stacktrace_rethrow_nonerror_test.cc2();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.bb2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.cc2 = function() {
    try {
      stacktrace_rethrow_nonerror_test.dd2();
    } catch (e$) {
      if (stacktrace_rethrow_nonerror_test.NotASubclassOfError.is(e$)) {
        let e = e$;
        throw e;
      } else if (core.int.is(e$)) {
        let e = e$;
        stacktrace_rethrow_nonerror_test.fail();
      } else
        throw e$;
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.cc2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.dd2 = function() {
    return stacktrace_rethrow_nonerror_test.ee2();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.dd2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ee2 = function() {
    try {
      stacktrace_rethrow_nonerror_test.ff2();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.ee2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ff2 = function() {
    return stacktrace_rethrow_nonerror_test.gg2();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.ff2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.gg2 = function() {
    return dart.throw(new stacktrace_rethrow_nonerror_test.NotASubclassOfError());
  };
  dart.fn(stacktrace_rethrow_nonerror_test.gg2, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.aa3 = function() {
    try {
      stacktrace_rethrow_nonerror_test.bb3();
      stacktrace_rethrow_nonerror_test.fail();
    } catch (exception) {
      let stacktrace = dart.stackTrace(exception);
      stacktrace_rethrow_nonerror_test.expectTrace(JSArrayOfString().of(['cc3', 'bb3', 'aa3']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.aa3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.bb3 = function() {
    return stacktrace_rethrow_nonerror_test.cc3();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.bb3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.cc3 = function() {
    try {
      stacktrace_rethrow_nonerror_test.dd3();
    } catch (e) {
      dart.throw(e);
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.cc3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.dd3 = function() {
    return stacktrace_rethrow_nonerror_test.ee3();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.dd3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ee3 = function() {
    try {
      stacktrace_rethrow_nonerror_test.ff3();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_nonerror_test.ee3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.ff3 = function() {
    return stacktrace_rethrow_nonerror_test.gg3();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.ff3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.gg3 = function() {
    return dart.throw(new stacktrace_rethrow_nonerror_test.NotASubclassOfError());
  };
  dart.fn(stacktrace_rethrow_nonerror_test.gg3, VoidTodynamic());
  stacktrace_rethrow_nonerror_test.expectTrace = function(functionNames, stacktrace) {
    let traceLines = dart.toString(stacktrace)[dartx.split]('\n');
    let expectedIndex = 0;
    let actualIndex = 0;
    core.print(stacktrace);
    core.print(functionNames);
    while (expectedIndex < dart.notNull(core.num._check(dart.dload(functionNames, 'length')))) {
      let expected = dart.dindex(functionNames, expectedIndex);
      let actual = traceLines[dartx.get](actualIndex);
      if (actual[dartx.indexOf](core.Pattern._check(expected)) == -1) {
        if (expectedIndex == 0) {
          actualIndex++;
        } else {
          dart.throw(dart.str`Expected: ${expected} actual: ${actual}`);
        }
      } else {
        actualIndex++;
        expectedIndex++;
      }
    }
  };
  dart.fn(stacktrace_rethrow_nonerror_test.expectTrace, dynamicAnddynamicTodynamic());
  stacktrace_rethrow_nonerror_test.main = function() {
    stacktrace_rethrow_nonerror_test.aa1();
    stacktrace_rethrow_nonerror_test.aa2();
    stacktrace_rethrow_nonerror_test.aa3();
  };
  dart.fn(stacktrace_rethrow_nonerror_test.main, VoidTodynamic());
  // Exports:
  exports.stacktrace_rethrow_nonerror_test = stacktrace_rethrow_nonerror_test;
});
