dart_library.library('destructuring', null, /* Imports */[
  'dart/_runtime',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, core) {
  'use strict';
  let dartx = dart.dartx;
  function f(a, b, c = 1) {
    f(a, b, c);
  }
  dart.fn(f, dart.dynamic, [core.int, dart.dynamic], [dart.dynamic]);
  function g(a, b, {c = 1} = {}) {
    f(a, b, c);
  }
  dart.fn(g, dart.dynamic, [core.int, dart.dynamic], {c: dart.dynamic});
  function invalid_names1(let$, func, arguments$) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names1, dart.dynamic, [core.int, dart.dynamic, dart.dynamic]);
  function invalid_names2(let$ = null, func = 1, arguments$ = null) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names2, dart.dynamic, [], [core.int, dart.dynamic, dart.dynamic]);
  function invalid_names3({["let"]: let$ = null, ["function"]: func = null, ["arguments"]: arguments$ = 2} = {}) {
    f(let$, func, arguments$);
  }
  dart.fn(invalid_names3, dart.dynamic, [], {let: core.int, function: dart.dynamic, arguments: dart.dynamic});
  function names_clashing_with_object_props({constructor = null, valueOf = null, hasOwnProperty = 2} = Object.create(null)) {
    f(constructor, valueOf, hasOwnProperty);
  }
  dart.fn(names_clashing_with_object_props, dart.dynamic, [], {constructor: core.int, valueOf: dart.dynamic, hasOwnProperty: dart.dynamic});
  // Exports:
  exports.f = f;
  exports.g = g;
  exports.invalid_names1 = invalid_names1;
  exports.invalid_names2 = invalid_names2;
  exports.invalid_names3 = invalid_names3;
  exports.names_clashing_with_object_props = names_clashing_with_object_props;
});
