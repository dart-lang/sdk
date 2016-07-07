dart_library.library('language/stacktrace_rethrow_error_test_withtraceparameter_multi', null, /* Imports */[
  'dart_sdk'
], function load__stacktrace_rethrow_error_test_withtraceparameter_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const stacktrace_rethrow_error_test_withtraceparameter_multi = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  stacktrace_rethrow_error_test_withtraceparameter_multi.SubclassOfError = class SubclassOfError extends core.Error {
    new() {
      super.new();
    }
  };
  stacktrace_rethrow_error_test_withtraceparameter_multi.fail = function() {
    return dart.throw("Fail");
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.fail, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.aa1 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.bb1();
      stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
    } catch (error) {
      let stacktrace = dart.stackTrace(error);
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1']), dart.dload(error, 'stackTrace'));
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.aa1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.bb1 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.cc1();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.bb1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.cc1 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.dd1();
    } catch (e$) {
      if (core.String.is(e$)) {
        let e = e$;
        stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
      } else if (core.int.is(e$)) {
        let e = e$;
        stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
      } else
        throw e$;
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.cc1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.dd1 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.ee1();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.dd1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ee1 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.ff1();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ee1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ff1 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.gg1();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ff1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.gg1 = function() {
    return dart.throw(new stacktrace_rethrow_error_test_withtraceparameter_multi.SubclassOfError());
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.gg1, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.aa2 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.bb2();
      stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
    } catch (error) {
      let stacktrace = dart.stackTrace(error);
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2']), dart.dload(error, 'stackTrace'));
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.aa2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.bb2 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.cc2();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.bb2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.cc2 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.dd2();
    } catch (e$) {
      if (stacktrace_rethrow_error_test_withtraceparameter_multi.SubclassOfError.is(e$)) {
        let e = e$;
        throw e;
      } else if (core.int.is(e$)) {
        let e = e$;
        stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
      } else
        throw e$;
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.cc2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.dd2 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.ee2();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.dd2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ee2 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.ff2();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ee2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ff2 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.gg2();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ff2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.gg2 = function() {
    return dart.throw(new stacktrace_rethrow_error_test_withtraceparameter_multi.SubclassOfError());
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.gg2, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.aa3 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.bb3();
      stacktrace_rethrow_error_test_withtraceparameter_multi.fail();
    } catch (error) {
      let stacktrace = dart.stackTrace(error);
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['gg3', 'ff3', 'ee3', 'dd3', 'cc3', 'bb3', 'aa3']), dart.dload(error, 'stackTrace'));
      stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace(JSArrayOfString().of(['cc3', 'bb3', 'aa3']), stacktrace);
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.aa3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.bb3 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.cc3();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.bb3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.cc3 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.dd3();
    } catch (e) {
      dart.throw(e);
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.cc3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.dd3 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.ee3();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.dd3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ee3 = function() {
    try {
      stacktrace_rethrow_error_test_withtraceparameter_multi.ff3();
    } catch (e) {
      throw e;
    }

  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ee3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.ff3 = function() {
    return stacktrace_rethrow_error_test_withtraceparameter_multi.gg3();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.ff3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.gg3 = function() {
    return dart.throw(new stacktrace_rethrow_error_test_withtraceparameter_multi.SubclassOfError());
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.gg3, VoidTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace = function(functionNames, stacktrace) {
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
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.expectTrace, dynamicAnddynamicTodynamic());
  stacktrace_rethrow_error_test_withtraceparameter_multi.main = function() {
    stacktrace_rethrow_error_test_withtraceparameter_multi.aa1();
    stacktrace_rethrow_error_test_withtraceparameter_multi.aa2();
    stacktrace_rethrow_error_test_withtraceparameter_multi.aa3();
  };
  dart.fn(stacktrace_rethrow_error_test_withtraceparameter_multi.main, VoidTodynamic());
  // Exports:
  exports.stacktrace_rethrow_error_test_withtraceparameter_multi = stacktrace_rethrow_error_test_withtraceparameter_multi;
});
