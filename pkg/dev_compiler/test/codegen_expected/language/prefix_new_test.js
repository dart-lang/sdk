dart_library.library('language/prefix_new_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix_new_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix_new_test = Object.create(null);
  const prefix_test1 = Object.create(null);
  const prefix_test2 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix_new_test.main = function() {
    expect$.Expect.equals(prefix_test1.Prefix.getSource(), dart.dsend(prefix_test1.Prefix.getImport(), '+', 1));
  };
  dart.fn(prefix_new_test.main, VoidTodynamic());
  prefix_test1.Prefix = class Prefix extends core.Object {
    static getSource() {
      return prefix_test1.Prefix.foo;
    }
    static getImport() {
      return prefix_test2.Prefix.foo;
    }
  };
  dart.setSignature(prefix_test1.Prefix, {
    statics: () => ({
      getSource: dart.definiteFunctionType(dart.dynamic, []),
      getImport: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['getSource', 'getImport']
  });
  prefix_test1.Prefix.foo = 43;
  prefix_test2.Prefix = class Prefix extends core.Object {};
  prefix_test2.Prefix.foo = 42;
  // Exports:
  exports.prefix_new_test = prefix_new_test;
  exports.prefix_test1 = prefix_test1;
  exports.prefix_test2 = prefix_test2;
});
