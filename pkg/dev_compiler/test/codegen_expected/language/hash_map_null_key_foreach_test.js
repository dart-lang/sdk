dart_library.library('language/hash_map_null_key_foreach_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hash_map_null_key_foreach_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hash_map_null_key_foreach_test = Object.create(null);
  let MapOfint$int = () => (MapOfint$int = dart.constFn(core.Map$(core.int, core.int)))();
  let intAndintTovoid = () => (intAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hash_map_null_key_foreach_test.main = function() {
    let x = MapOfint$int().new();
    x[dartx.set](1, 2);
    x[dartx.set](null, 1);
    let c = 0;
    x[dartx.forEach](dart.fn((i, j) => {
      c++;
      expect$.Expect.isTrue(i == null || typeof i == 'number', 'int or null expected');
    }, intAndintTovoid()));
    expect$.Expect.equals(2, c);
  };
  dart.fn(hash_map_null_key_foreach_test.main, VoidTodynamic());
  // Exports:
  exports.hash_map_null_key_foreach_test = hash_map_null_key_foreach_test;
});
