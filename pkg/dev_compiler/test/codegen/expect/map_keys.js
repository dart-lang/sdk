dart_library.library('map_keys', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const map_keys = Object.create(null);
  map_keys.main = function() {
    core.print(dart.map({'1': 2, '3': 4, '5': 6}));
    core.print(dart.map([1, 2, 3, 4, 5, 6]));
    core.print(dart.map({'1': 2, [`${dart.notNull(math.Random.new().nextInt(2)) + 2}`]: 4, '5': 6}));
    let x = '3';
    core.print(dart.map(['1', 2, x, 4, '5', 6]));
    core.print(dart.map(['1', 2, null, 4, '5', 6]));
  };
  dart.fn(map_keys.main);
  // Exports:
  exports.map_keys = map_keys;
});

//# sourceMappingURL=map_keys.js.map
