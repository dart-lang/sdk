dart_library.library('language/metadata_self_test', null, /* Imports */[
  'dart_sdk'
], function load__metadata_self_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const metadata_self_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  metadata_self_test.Foo = class Foo extends core.Object {
    new() {
    }
  };
  dart.setSignature(metadata_self_test.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(metadata_self_test.Foo, [])})
  });
  let const$;
  metadata_self_test.main = function() {
    let f = const$ || (const$ = dart.const(new metadata_self_test.Foo()));
  };
  dart.fn(metadata_self_test.main, VoidTodynamic());
  // Exports:
  exports.metadata_self_test = metadata_self_test;
});
