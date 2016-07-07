dart_library.library('language/hello_dart_test', null, /* Imports */[
  'dart_sdk'
], function load__hello_dart_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const hello_dart_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hello_dart_test.HelloDartTest = class HelloDartTest extends core.Object {
    static testMain() {
      core.print("Hello, Darter!");
    }
  };
  dart.setSignature(hello_dart_test.HelloDartTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  hello_dart_test.main = function() {
    hello_dart_test.HelloDartTest.testMain();
  };
  dart.fn(hello_dart_test.main, VoidTodynamic());
  // Exports:
  exports.hello_dart_test = hello_dart_test;
});
