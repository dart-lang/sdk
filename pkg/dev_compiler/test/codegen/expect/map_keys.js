dart_library.library('map_keys', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/math'
], /* Lazy imports */[
], function(exports, dart, core, math) {
  'use strict';
  let dartx = dart.dartx;
  function main() {
    core.print(dart.map({'1': 2, '3': 4, '5': 6}));
    core.print(dart.map([1, 2, 3, 4, 5, 6]));
    core.print(dart.map({'1': 2, [`${dart.notNull(math.Random.new().nextInt(2)) + 2}`]: 4, '5': 6}));
    let x = '3';
    core.print(dart.map(['1', 2, x, 4, '5', 6]));
    core.print(dart.map(['1', 2, null, 4, '5', 6]));
  }
  dart.fn(main);
  // Exports:
  exports.main = main;
});
//# sourceMappingURL=map_keys.js.map
