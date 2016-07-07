dart_library.library('corelib/hash_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hash_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hash_map_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hash_map_test.HashMapTest = class HashMapTest extends core.Object {
    static testMain() {
      let m = core.Map.new();
      expect$.Expect.equals(0, m[dartx.length]);
      expect$.Expect.equals(true, m[dartx.isEmpty]);
      m[dartx.set]("one", 1);
      expect$.Expect.equals(1, m[dartx.length]);
      expect$.Expect.equals(false, m[dartx.isEmpty]);
      expect$.Expect.equals(1, m[dartx.get]("one"));
    }
  };
  dart.setSignature(hash_map_test.HashMapTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  hash_map_test.main = function() {
    hash_map_test.HashMapTest.testMain();
  };
  dart.fn(hash_map_test.main, VoidTodynamic());
  // Exports:
  exports.hash_map_test = hash_map_test;
});
