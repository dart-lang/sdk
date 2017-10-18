define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const _root = Object.create(null);
  const map_keys = Object.create(_root);
  let IdentityMapOfString$int = () => (IdentityMapOfString$int = dart.constFn(_js_helper.IdentityMap$(core.String, core.int)))();
  let IdentityMapOfint$int = () => (IdentityMapOfint$int = dart.constFn(_js_helper.IdentityMap$(core.int, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
  map_keys.main = function() {
    core.print(new (IdentityMapOfString$int()).from(['1', 2, '3', 4, '5', 6]));
    core.print(new (IdentityMapOfint$int()).from([1, 2, 3, 4, 5, 6]));
    core.print(new (IdentityMapOfString$int()).from(['1', 2, dart.str`${dart.notNull(math.Random.new().nextInt(2)) + 2}`, 4, '5', 6]));
    let x = '3';
    core.print(new (IdentityMapOfString$int()).from(['1', 2, x, 4, '5', 6]));
    core.print(new (IdentityMapOfString$int()).from(['1', 2, null, 4, '5', 6]));
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
