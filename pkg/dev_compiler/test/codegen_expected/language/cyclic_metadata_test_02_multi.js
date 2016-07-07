dart_library.library('language/cyclic_metadata_test_02_multi', null, /* Imports */[
  'dart_sdk'
], function load__cyclic_metadata_test_02_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cyclic_metadata_test_02_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  cyclic_metadata_test_02_multi.Super = class Super extends core.Object {
    new(field) {
      this.field = field;
    }
  };
  dart.setSignature(cyclic_metadata_test_02_multi.Super, {
    constructors: () => ({new: dart.definiteFunctionType(cyclic_metadata_test_02_multi.Super, [dart.dynamic])})
  });
  cyclic_metadata_test_02_multi.Sub1 = class Sub1 extends cyclic_metadata_test_02_multi.Super {
    new(field) {
      super.new(field);
    }
  };
  dart.setSignature(cyclic_metadata_test_02_multi.Sub1, {
    constructors: () => ({new: dart.definiteFunctionType(cyclic_metadata_test_02_multi.Sub1, [dart.dynamic])})
  });
  cyclic_metadata_test_02_multi.Sub2 = class Sub2 extends cyclic_metadata_test_02_multi.Super {
    new(field) {
      super.new(field);
    }
  };
  dart.setSignature(cyclic_metadata_test_02_multi.Sub2, {
    constructors: () => ({new: dart.definiteFunctionType(cyclic_metadata_test_02_multi.Sub2, [dart.dynamic])})
  });
  cyclic_metadata_test_02_multi.main = function() {
    core.print(new cyclic_metadata_test_02_multi.Super(1));
  };
  dart.fn(cyclic_metadata_test_02_multi.main, VoidTovoid());
  // Exports:
  exports.cyclic_metadata_test_02_multi = cyclic_metadata_test_02_multi;
});
