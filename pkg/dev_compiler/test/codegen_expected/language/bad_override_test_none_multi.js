dart_library.library('language/bad_override_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__bad_override_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const bad_override_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bad_override_test_none_multi.Fisk = class Fisk extends core.Object {
    new() {
      this.field = null;
    }
    get fisk() {
      return null;
    }
    set fisk(x) {}
    get hest() {
      return null;
    }
    set hest(x) {}
    foo() {}
    method() {}
    nullary() {}
  };
  dart.setSignature(bad_override_test_none_multi.Fisk, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      method: dart.definiteFunctionType(dart.dynamic, []),
      nullary: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  bad_override_test_none_multi.Hest = class Hest extends bad_override_test_none_multi.Fisk {
    new() {
      super.new();
    }
  };
  bad_override_test_none_multi.main = function() {
    new bad_override_test_none_multi.Fisk();
    new bad_override_test_none_multi.Hest();
  };
  dart.fn(bad_override_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.bad_override_test_none_multi = bad_override_test_none_multi;
});
