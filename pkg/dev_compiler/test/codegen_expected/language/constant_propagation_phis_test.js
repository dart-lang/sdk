dart_library.library('language/constant_propagation_phis_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constant_propagation_phis_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constant_propagation_phis_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  constant_propagation_phis_test.keys = dart.constList(["keyA"], core.String);
  constant_propagation_phis_test.values = dart.constList(["a"], core.String);
  constant_propagation_phis_test.main = function() {
    for (let i = 0; i < 20; i++)
      constant_propagation_phis_test.test(constant_propagation_phis_test.keys[dartx.get](0));
  };
  dart.fn(constant_propagation_phis_test.main, VoidTodynamic());
  constant_propagation_phis_test.test = function(key) {
    let ref = constant_propagation_phis_test.key2value(key);
    expect$.Expect.equals("a", ref == null ? "-" : ref);
  };
  dart.fn(constant_propagation_phis_test.test, dynamicTodynamic());
  constant_propagation_phis_test.key2value = function(key) {
    let index = constant_propagation_phis_test.indexOf(constant_propagation_phis_test.keys, key);
    return dart.equals(index, -1) ? null : constant_propagation_phis_test.values[dartx.get](core.int._check(index));
  };
  dart.fn(constant_propagation_phis_test.key2value, dynamicTodynamic());
  constant_propagation_phis_test.indexOf = function(keys, key) {
    for (let i = dart.dsend(dart.dload(keys, 'length'), '-', 1); dart.test(dart.dsend(i, '>=', 0)); i = dart.dsend(i, '-', 1)) {
      let equals = dart.equals(dart.dindex(keys, i), key);
      if (equals) return i;
    }
    return -1;
  };
  dart.fn(constant_propagation_phis_test.indexOf, dynamicAnddynamicTodynamic());
  // Exports:
  exports.constant_propagation_phis_test = constant_propagation_phis_test;
});
