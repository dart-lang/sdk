dart_library.library('language/map_literal5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal5_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let boolTovoid = () => (boolTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool])))();
  let boolTodynamic = () => (boolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.bool])))();
  map_literal5_test.main = function() {
    map_literal5_test.test(true);
    map_literal5_test.test(false);
  };
  dart.fn(map_literal5_test.main, VoidTovoid());
  map_literal5_test.test = function(b) {
    let m = map_literal5_test.create(b);
    expect$.Expect.equals(b, dart.dsend(m, 'containsKey', true));
    expect$.Expect.equals(b, dart.dsend(m, 'containsKey', 2));
    expect$.Expect.equals(b, dart.dsend(m, 'containsKey', 1));
    expect$.Expect.equals(!dart.test(b), dart.dsend(m, 'containsKey', false));
    expect$.Expect.equals(!dart.test(b), dart.dsend(m, 'containsKey', "bar"));
    expect$.Expect.equals(!dart.test(b), dart.dsend(m, 'containsKey', "foo"));
    if (dart.test(b)) {
      expect$.Expect.equals(0, dart.dindex(m, true));
      expect$.Expect.equals(3, dart.dindex(m, 2));
      expect$.Expect.equals(2, dart.dindex(m, 1));
    } else {
      expect$.Expect.equals(0, dart.dindex(m, false));
      expect$.Expect.equals("baz", dart.dindex(m, "bar"));
      expect$.Expect.equals(2, dart.dindex(m, "foo"));
    }
  };
  dart.fn(map_literal5_test.test, boolTovoid());
  map_literal5_test.create = function(b) {
    return dart.map([b, 0, map_literal5_test.m(b), map_literal5_test.n(b), dart.test(b) ? 1 : "foo", 2]);
  };
  dart.fn(map_literal5_test.create, boolTodynamic());
  map_literal5_test.m = function(b) {
    return dart.test(b) ? 2 : "bar";
  };
  dart.fn(map_literal5_test.m, boolTodynamic());
  map_literal5_test.n = function(b) {
    return dart.test(b) ? 3 : "baz";
  };
  dart.fn(map_literal5_test.n, boolTodynamic());
  // Exports:
  exports.map_literal5_test = map_literal5_test;
});
