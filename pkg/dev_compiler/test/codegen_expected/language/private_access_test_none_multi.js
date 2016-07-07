dart_library.library('language/private_access_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__private_access_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const private_access_test_none_multi = Object.create(null);
  const private_access_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  private_access_test_none_multi.main = function() {
  };
  dart.fn(private_access_test_none_multi.main, VoidTodynamic());
  private_access_lib._function = function() {
  };
  dart.fn(private_access_lib._function, VoidTodynamic());
  private_access_lib._Class = class _Class extends core.Object {};
  private_access_lib.Class = class Class extends core.Object {
    _constructor() {
    }
  };
  dart.defineNamedConstructor(private_access_lib.Class, '_constructor');
  dart.setSignature(private_access_lib.Class, {
    constructors: () => ({_constructor: dart.definiteFunctionType(private_access_lib.Class, [])})
  });
  // Exports:
  exports.private_access_test_none_multi = private_access_test_none_multi;
  exports.private_access_lib = private_access_lib;
});
