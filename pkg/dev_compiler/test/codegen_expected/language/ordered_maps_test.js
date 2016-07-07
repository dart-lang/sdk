dart_library.library('language/ordered_maps_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ordered_maps_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ordered_maps_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  ordered_maps_test.OrderedMapsTest = class OrderedMapsTest extends core.Object {
    static testMain() {
      ordered_maps_test.OrderedMapsTest.testMaps(const$ || (const$ = dart.const(dart.map({a: 1, c: 2}))), const$0 || (const$0 = dart.const(dart.map({c: 2, a: 1}))), true);
      ordered_maps_test.OrderedMapsTest.testMaps(dart.map({a: 1, c: 2}), dart.map({c: 2, a: 1}), false);
    }
    static testMaps(map1, map2, isConst) {
      expect$.Expect.isFalse(core.identical(map1, map2));
      let keys = dart.dsend(dart.dload(map1, 'keys'), 'toList');
      expect$.Expect.equals(2, dart.dload(keys, 'length'));
      expect$.Expect.equals("a", dart.dindex(keys, 0));
      expect$.Expect.equals("c", dart.dindex(keys, 1));
      keys = dart.dsend(dart.dload(map2, 'keys'), 'toList');
      expect$.Expect.equals(2, dart.dload(keys, 'length'));
      expect$.Expect.equals("c", dart.dindex(keys, 0));
      expect$.Expect.equals("a", dart.dindex(keys, 1));
      let values = dart.dsend(dart.dload(map1, 'values'), 'toList');
      expect$.Expect.equals(2, dart.dload(values, 'length'));
      expect$.Expect.equals(1, dart.dindex(values, 0));
      expect$.Expect.equals(2, dart.dindex(values, 1));
      values = dart.dsend(dart.dload(map2, 'values'), 'toList');
      expect$.Expect.equals(2, dart.dload(values, 'length'));
      expect$.Expect.equals(2, dart.dindex(values, 0));
      expect$.Expect.equals(1, dart.dindex(values, 1));
      if (dart.test(isConst)) return;
      dart.dsetindex(map1, "b", 3);
      dart.dsetindex(map2, "b", 3);
      keys = dart.dsend(dart.dload(map1, 'keys'), 'toList');
      expect$.Expect.equals(3, dart.dload(keys, 'length'));
      expect$.Expect.equals("a", dart.dindex(keys, 0));
      expect$.Expect.equals("c", dart.dindex(keys, 1));
      expect$.Expect.equals("b", dart.dindex(keys, 2));
      keys = dart.dsend(dart.dload(map2, 'keys'), 'toList');
      expect$.Expect.equals(3, dart.dload(keys, 'length'));
      expect$.Expect.equals("c", dart.dindex(keys, 0));
      expect$.Expect.equals("a", dart.dindex(keys, 1));
      expect$.Expect.equals("b", dart.dindex(keys, 2));
      values = dart.dsend(dart.dload(map1, 'values'), 'toList');
      expect$.Expect.equals(3, dart.dload(values, 'length'));
      expect$.Expect.equals(1, dart.dindex(values, 0));
      expect$.Expect.equals(2, dart.dindex(values, 1));
      expect$.Expect.equals(3, dart.dindex(values, 2));
      values = dart.dsend(dart.dload(map2, 'values'), 'toList');
      expect$.Expect.equals(3, dart.dload(values, 'length'));
      expect$.Expect.equals(2, dart.dindex(values, 0));
      expect$.Expect.equals(1, dart.dindex(values, 1));
      expect$.Expect.equals(3, dart.dindex(values, 2));
      dart.dsetindex(map1, "a", 4);
      keys = dart.dsend(dart.dload(map1, 'keys'), 'toList');
      expect$.Expect.equals(3, dart.dload(keys, 'length'));
      expect$.Expect.equals("a", dart.dindex(keys, 0));
      values = dart.dsend(dart.dload(map1, 'values'), 'toList');
      expect$.Expect.equals(3, dart.dload(values, 'length'));
      expect$.Expect.equals(4, dart.dindex(values, 0));
    }
  };
  dart.setSignature(ordered_maps_test.OrderedMapsTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      testMaps: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.bool])
    }),
    names: ['testMain', 'testMaps']
  });
  ordered_maps_test.main = function() {
    ordered_maps_test.OrderedMapsTest.testMain();
  };
  dart.fn(ordered_maps_test.main, VoidTodynamic());
  // Exports:
  exports.ordered_maps_test = ordered_maps_test;
});
