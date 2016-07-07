dart_library.library('language/null2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null2_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null2_test.confuse = function(x) {
    try {
      if (new core.DateTime.now().millisecondsSinceEpoch == 42) x = 42;
      dart.throw([x]);
    } catch (e) {
      if (dart.dynamic.is(e)) {
        return dart.dindex(e, 0);
      } else
        throw e;
    }

    return 42;
  };
  dart.fn(null2_test.confuse, dynamicTodynamic());
  null2_test.main = function() {
    expect$.Expect.equals("Null", dart.toString(dart.runtimeType(null)));
    expect$.Expect.equals("Null", dart.toString(dart.runtimeType(null2_test.confuse(null))));
  };
  dart.fn(null2_test.main, VoidTodynamic());
  // Exports:
  exports.null2_test = null2_test;
});
