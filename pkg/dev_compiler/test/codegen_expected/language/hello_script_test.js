dart_library.library('language/hello_script_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hello_script_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hello_script_test = Object.create(null);
  const hello_script_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hello_script_test.main = function() {
    hello_script_lib.HelloLib.doTest();
    expect$.Expect.equals(18, hello_script_lib.x);
    core.print("Hello done.");
  };
  dart.fn(hello_script_test.main, VoidTodynamic());
  hello_script_lib.HelloLib = class HelloLib extends core.Object {
    static doTest() {
      hello_script_lib.x = 17;
      expect$.Expect.equals(17, (() => {
        let x = hello_script_lib.x;
        hello_script_lib.x = dart.dsend(x, '+', 1);
        return x;
      })());
      core.print("Hello from Lib!");
    }
  };
  dart.setSignature(hello_script_lib.HelloLib, {
    statics: () => ({doTest: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['doTest']
  });
  hello_script_lib.x = null;
  // Exports:
  exports.hello_script_test = hello_script_test;
  exports.hello_script_lib = hello_script_lib;
});
