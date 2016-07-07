dart_library.library('language/issue10561_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10561_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10561_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10561_test.Foo = class Foo extends core.Expando {
    new() {
      super.new();
    }
  };
  dart.addSimpleTypeTests(issue10561_test.Foo);
  issue10561_test.main = function() {
    expect$.Expect.isNull(new issue10561_test.Foo().get(new core.Object()));
  };
  dart.fn(issue10561_test.main, VoidTodynamic());
  // Exports:
  exports.issue10561_test = issue10561_test;
});
