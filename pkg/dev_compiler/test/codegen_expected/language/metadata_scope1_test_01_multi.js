dart_library.library('language/metadata_scope1_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__metadata_scope1_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const metadata_scope1_test_01_multi = Object.create(null);
  let Foo = () => (Foo = dart.constFn(metadata_scope1_test_01_multi.Foo$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  metadata_scope1_test_01_multi.Foo$ = dart.generic(deprecated => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.dynamic, []));
    return Foo;
  });
  metadata_scope1_test_01_multi.Foo = Foo();
  metadata_scope1_test_01_multi.main = function() {
    let f = null;
  };
  dart.fn(metadata_scope1_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.metadata_scope1_test_01_multi = metadata_scope1_test_01_multi;
});
