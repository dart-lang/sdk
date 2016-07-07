dart_library.library('language/bad_named_parameters2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__bad_named_parameters2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const bad_named_parameters2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bad_named_parameters2_test_none_multi.BadNamedParameters2Test = class BadNamedParameters2Test extends core.Object {
    foo(a) {
      return a;
    }
    static testMain() {
      let np = new bad_named_parameters2_test_none_multi.BadNamedParameters2Test();
      let caught = null;
      try {
        caught = false;
      } catch (e) {
        if (core.NoSuchMethodError.is(e)) {
          caught = true;
        } else
          throw e;
      }

    }
  };
  dart.setSignature(bad_named_parameters2_test_none_multi.BadNamedParameters2Test, {
    methods: () => ({foo: dart.definiteFunctionType(core.int, [core.int])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  bad_named_parameters2_test_none_multi.main = function() {
    bad_named_parameters2_test_none_multi.BadNamedParameters2Test.testMain();
  };
  dart.fn(bad_named_parameters2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.bad_named_parameters2_test_none_multi = bad_named_parameters2_test_none_multi;
});
