dart_library.library('language/map_literal11_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal11_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal11_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let MapTovoid = () => (MapTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Map])))();
  map_literal11_test.foo = function(m) {
    expect$.Expect.throws(dart.fn(() => {
      m[dartx.set](23, 23);
    }, VoidTovoid()), dart.fn(e => core.TypeError.is(e), dynamicTobool()));
  };
  dart.fn(map_literal11_test.foo, MapTovoid());
  map_literal11_test.main = function() {
    let map = dart.map({}, core.String, dart.dynamic);
    map_literal11_test.foo(map);
  };
  dart.fn(map_literal11_test.main, VoidTovoid());
  // Exports:
  exports.map_literal11_test = map_literal11_test;
});
