dart_library.library('language/compile_time_constant_checked5_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__compile_time_constant_checked5_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const compile_time_constant_checked5_test_none_multi = Object.create(null);
  let Test2 = () => (Test2 = dart.constFn(compile_time_constant_checked5_test_none_multi.Test2$()))();
  let Test3 = () => (Test3 = dart.constFn(compile_time_constant_checked5_test_none_multi.Test3$()))();
  let Test4 = () => (Test4 = dart.constFn(compile_time_constant_checked5_test_none_multi.Test4$()))();
  let Test5 = () => (Test5 = dart.constFn(compile_time_constant_checked5_test_none_multi.Test5$()))();
  let Test2OfA$B = () => (Test2OfA$B = dart.constFn(compile_time_constant_checked5_test_none_multi.Test2$(compile_time_constant_checked5_test_none_multi.A, compile_time_constant_checked5_test_none_multi.B)))();
  let Test3OfA$B = () => (Test3OfA$B = dart.constFn(compile_time_constant_checked5_test_none_multi.Test3$(compile_time_constant_checked5_test_none_multi.A, compile_time_constant_checked5_test_none_multi.B)))();
  let Test4OfA$B = () => (Test4OfA$B = dart.constFn(compile_time_constant_checked5_test_none_multi.Test4$(compile_time_constant_checked5_test_none_multi.A, compile_time_constant_checked5_test_none_multi.B)))();
  let Test5OfA$B = () => (Test5OfA$B = dart.constFn(compile_time_constant_checked5_test_none_multi.Test5$(compile_time_constant_checked5_test_none_multi.A, compile_time_constant_checked5_test_none_multi.B)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_checked5_test_none_multi.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(compile_time_constant_checked5_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.A, [])})
  });
  compile_time_constant_checked5_test_none_multi.B = class B extends compile_time_constant_checked5_test_none_multi.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(compile_time_constant_checked5_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.B, [])})
  });
  compile_time_constant_checked5_test_none_multi.C = class C extends compile_time_constant_checked5_test_none_multi.A {
    new() {
      super.new();
    }
    static d() {
      return new compile_time_constant_checked5_test_none_multi.D();
    }
  };
  dart.setSignature(compile_time_constant_checked5_test_none_multi.C, {
    constructors: () => ({
      new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.C, []),
      d: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.C, [])
    })
  });
  compile_time_constant_checked5_test_none_multi.D = class D extends compile_time_constant_checked5_test_none_multi.B {
    new() {
      super.new();
    }
  };
  compile_time_constant_checked5_test_none_multi.D[dart.implements] = () => [compile_time_constant_checked5_test_none_multi.C];
  dart.setSignature(compile_time_constant_checked5_test_none_multi.D, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.D, [])})
  });
  compile_time_constant_checked5_test_none_multi.Test1 = class Test1 extends core.Object {
    new() {
    }
  };
  dart.setSignature(compile_time_constant_checked5_test_none_multi.Test1, {
    constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.Test1, [])})
  });
  compile_time_constant_checked5_test_none_multi.Test2$ = dart.generic((U, V) => {
    class Test2 extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Test2);
    dart.setSignature(Test2, {
      constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.Test2$(U, V), [])})
    });
    return Test2;
  });
  compile_time_constant_checked5_test_none_multi.Test2 = Test2();
  compile_time_constant_checked5_test_none_multi.Test3$ = dart.generic((U, V) => {
    class Test3 extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Test3);
    dart.setSignature(Test3, {
      constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.Test3$(U, V), [])})
    });
    return Test3;
  });
  compile_time_constant_checked5_test_none_multi.Test3 = Test3();
  compile_time_constant_checked5_test_none_multi.Test4$ = dart.generic((U, V) => {
    class Test4 extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Test4);
    dart.setSignature(Test4, {
      constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.Test4$(U, V), [])})
    });
    return Test4;
  });
  compile_time_constant_checked5_test_none_multi.Test4 = Test4();
  compile_time_constant_checked5_test_none_multi.Test5$ = dart.generic((U, V) => {
    class Test5 extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Test5);
    dart.setSignature(Test5, {
      constructors: () => ({new: dart.definiteFunctionType(compile_time_constant_checked5_test_none_multi.Test5$(U, V), [])})
    });
    return Test5;
  });
  compile_time_constant_checked5_test_none_multi.Test5 = Test5();
  compile_time_constant_checked5_test_none_multi.use = function(x) {
    return x;
  };
  dart.fn(compile_time_constant_checked5_test_none_multi.use, dynamicTodynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  compile_time_constant_checked5_test_none_multi.main = function() {
    compile_time_constant_checked5_test_none_multi.use(const$ || (const$ = dart.const(new compile_time_constant_checked5_test_none_multi.Test1())));
    compile_time_constant_checked5_test_none_multi.use(const$0 || (const$0 = dart.const(new (Test2OfA$B())())));
    compile_time_constant_checked5_test_none_multi.use(const$1 || (const$1 = dart.const(new (Test3OfA$B())())));
    compile_time_constant_checked5_test_none_multi.use(const$2 || (const$2 = dart.const(new (Test4OfA$B())())));
    compile_time_constant_checked5_test_none_multi.use(const$3 || (const$3 = dart.const(new (Test5OfA$B())())));
  };
  dart.fn(compile_time_constant_checked5_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_checked5_test_none_multi = compile_time_constant_checked5_test_none_multi;
});
