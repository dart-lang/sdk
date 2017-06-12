define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const map_keys = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
  map_keys.main = function() {
    core.print(dart.map({'1': 2, '3': 4, '5': 6}, core.String, core.int));
    core.print(dart.map([1, 2, 3, 4, 5, 6], core.int, core.int));
    core.print(dart.map({'1': 2, [dart.str`${dart.notNull(math.Random.new().nextInt(2)) + 2}`]: 4, '5': 6}, core.String, core.int));
    let x = '3';
    core.print(dart.map(['1', 2, x, 4, '5', 6], core.String, core.int));
    core.print(dart.map(['1', 2, null, 4, '5', 6], core.String, core.int));
  };
  dart.fn(map_keys.main, VoidTodynamic());
  dart.trackLibraries("map_keys", {
    "map_keys.dart": map_keys
  }, null);
  // Exports:
  return {
    map_keys: map_keys
  };
});

//# sourceMappingURL=map_keys.js.map
