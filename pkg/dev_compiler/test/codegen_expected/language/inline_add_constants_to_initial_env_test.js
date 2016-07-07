dart_library.library('language/inline_add_constants_to_initial_env_test', null, /* Imports */[
  'dart_sdk'
], function load__inline_add_constants_to_initial_env_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const inline_add_constants_to_initial_env_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_add_constants_to_initial_env_test.h = function(x, y) {
    return dart.equals(x, y);
  };
  dart.fn(inline_add_constants_to_initial_env_test.h, dynamicAnddynamicTodynamic());
  inline_add_constants_to_initial_env_test.g = function(y, x0, x1, x2, x3) {
    if (x0 === void 0) x0 = 0;
    if (x1 === void 0) x1 = 1;
    if (x2 === void 0) x2 = 2;
    if (x3 === void 0) x3 = 3;
    return dart.dsend(dart.dsend(dart.dsend(dart.dsend(y, '+', x0), '+', x1), '+', x2), '+', x3);
  };
  dart.fn(inline_add_constants_to_initial_env_test.g, dynamic__Todynamic());
  inline_add_constants_to_initial_env_test.f = function(y) {
    return inline_add_constants_to_initial_env_test.h(y, inline_add_constants_to_initial_env_test.g(y));
  };
  dart.fn(inline_add_constants_to_initial_env_test.f, dynamicTodynamic());
  inline_add_constants_to_initial_env_test.main = function() {
    for (let i = 0; i < 20; i++)
      inline_add_constants_to_initial_env_test.f(i);
  };
  dart.fn(inline_add_constants_to_initial_env_test.main, VoidTodynamic());
  // Exports:
  exports.inline_add_constants_to_initial_env_test = inline_add_constants_to_initial_env_test;
});
