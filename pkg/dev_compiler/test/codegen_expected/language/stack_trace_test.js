dart_library.library('language/stack_trace_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stack_trace_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stack_trace_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  stack_trace_test.MyException = class MyException extends core.Object {
    new(message) {
      this.message_ = message;
    }
  };
  dart.setSignature(stack_trace_test.MyException, {
    constructors: () => ({new: dart.definiteFunctionType(stack_trace_test.MyException, [core.String])})
  });
  stack_trace_test.Helper = class Helper extends core.Object {
    static f1(i) {
      try {
        i = stack_trace_test.Helper.func();
        i = 10;
      } catch (exception) {
        if (stack_trace_test.MyException.is(exception)) {
          let stacktrace = dart.stackTrace(exception);
          i = 50;
          core.print(exception.message_);
          expect$.Expect.isNotNull(stacktrace);
          core.print(stacktrace);
        } else
          throw exception;
      }

      try {
        let j = null;
        i = stack_trace_test.Helper.func1();
        i = 200;
      } catch (exception) {
        if (stack_trace_test.MyException.is(exception)) {
          let stacktrace = dart.stackTrace(exception);
          i = 50;
          core.print(exception.message_);
          expect$.Expect.isNotNull(stacktrace);
          core.print(stacktrace);
        } else
          throw exception;
      }

      try {
        let j = null;
        i = stack_trace_test.Helper.func2();
        i = 200;
      } catch (exception) {
        if (stack_trace_test.MyException.is(exception)) {
          let stacktrace = dart.stackTrace(exception);
          i = 50;
          core.print(exception.message_);
          expect$.Expect.isNotNull(stacktrace);
          core.print(stacktrace);
        } else
          throw exception;
      }
 finally {
        i = dart.notNull(i) + 800;
      }
      return i;
    }
    static func() {
      let i = 0;
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        dart.throw(new stack_trace_test.MyException("Exception Test for stack trace being printed"));
      }
      return 10;
    }
    static func1() {
      try {
        stack_trace_test.Helper.func();
      } catch (exception) {
        if (stack_trace_test.MyException.is(exception)) {
          dart.throw(new stack_trace_test.MyException("Exception Test for stack trace being printed"));
          ;
        } else
          throw exception;
      }

      return 10;
    }
    static func2() {
      try {
        stack_trace_test.Helper.func();
      } catch (exception) {
        if (stack_trace_test.MyException.is(exception)) {
          throw exception;
        } else
          throw exception;
      }

      return 10;
    }
  };
  dart.setSignature(stack_trace_test.Helper, {
    statics: () => ({
      f1: dart.definiteFunctionType(core.int, [core.int]),
      func: dart.definiteFunctionType(core.int, []),
      func1: dart.definiteFunctionType(core.int, []),
      func2: dart.definiteFunctionType(core.int, [])
    }),
    names: ['f1', 'func', 'func1', 'func2']
  });
  stack_trace_test.StackTraceTest = class StackTraceTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(850, stack_trace_test.Helper.f1(1));
    }
  };
  dart.setSignature(stack_trace_test.StackTraceTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  stack_trace_test.RethrowStacktraceTest = class RethrowStacktraceTest extends core.Object {
    new() {
      this.config = 0;
    }
    issue12940() {
      dart.throw("Progy");
    }
    b() {
      this.issue12940();
    }
    c() {
      if (this.config == 0) {
        try {
          this.b();
        } catch (e) {
          throw e;
        }

      } else {
        try {
          this.b();
        } catch (e) {
          let s = dart.stackTrace(e);
          throw e;
        }

      }
    }
    d() {
      this.c();
    }
    testBoth() {
      for (this.config = 0; dart.notNull(this.config) < 2; this.config = dart.notNull(this.config) + 1) {
        try {
          this.d();
        } catch (e) {
          let s = dart.stackTrace(e);
          expect$.Expect.isTrue(s.toString()[dartx.contains]("issue12940"));
        }

      }
    }
    static testMain() {
      let test = new stack_trace_test.RethrowStacktraceTest();
      test.testBoth();
    }
  };
  dart.setSignature(stack_trace_test.RethrowStacktraceTest, {
    methods: () => ({
      issue12940: dart.definiteFunctionType(dart.dynamic, []),
      b: dart.definiteFunctionType(dart.dynamic, []),
      c: dart.definiteFunctionType(dart.dynamic, []),
      d: dart.definiteFunctionType(dart.dynamic, []),
      testBoth: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  stack_trace_test.main = function() {
    stack_trace_test.StackTraceTest.testMain();
    stack_trace_test.RethrowStacktraceTest.testMain();
  };
  dart.fn(stack_trace_test.main, VoidTodynamic());
  // Exports:
  exports.stack_trace_test = stack_trace_test;
});
