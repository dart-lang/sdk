dart_library.library('language/execute_finally8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__execute_finally8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const execute_finally8_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  execute_finally8_test.Hello = class Hello extends core.Object {
    static foo() {
      execute_finally8_test.Hello.sum = 0;
      try {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        return 'hi';
      } finally {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        dart.throw('ball');
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
      }
    }
    static foo1() {
      let loop = true;
      execute_finally8_test.Hello.sum = 0;
      L:
        while (loop) {
          try {
            execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
            return 'hi';
          } finally {
            execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
            break L;
            execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
          }
        }
    }
    static foo2() {
      let loop = true;
      execute_finally8_test.Hello.sum = 0;
      try {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        return 'hi';
      } finally {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        return 10;
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
      }
    }
    static foo3() {
      execute_finally8_test.Hello.sum = 0;
      try {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        return 'hi';
      } finally {
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
        return 10;
        execute_finally8_test.Hello.sum = dart.dsend(execute_finally8_test.Hello.sum, '+', 1);
      }
    }
    static main() {
      execute_finally8_test.Hello.foo1();
      expect$.Expect.equals(2, execute_finally8_test.Hello.sum);
      execute_finally8_test.Hello.foo2();
      expect$.Expect.equals(2, execute_finally8_test.Hello.sum);
      execute_finally8_test.Hello.foo3();
      expect$.Expect.equals(2, execute_finally8_test.Hello.sum);
      try {
        execute_finally8_test.Hello.foo();
      } catch (e) {
      }

      expect$.Expect.equals(2, execute_finally8_test.Hello.sum);
    }
  };
  dart.setSignature(execute_finally8_test.Hello, {
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      foo1: dart.definiteFunctionType(dart.dynamic, []),
      foo2: dart.definiteFunctionType(dart.dynamic, []),
      foo3: dart.definiteFunctionType(dart.dynamic, []),
      main: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['foo', 'foo1', 'foo2', 'foo3', 'main']
  });
  execute_finally8_test.Hello.sum = null;
  execute_finally8_test.main = function() {
    execute_finally8_test.Hello.main();
  };
  dart.fn(execute_finally8_test.main, VoidTodynamic());
  // Exports:
  exports.execute_finally8_test = execute_finally8_test;
});
