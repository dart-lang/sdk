dart_library.library('language/static_setter_get_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__static_setter_get_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const static_setter_get_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_setter_get_test_none_multi.Class = class Class extends core.Object {
    static set o(_) {}
    noSuchMethod(_) {
      return 42;
    }
  };
  static_setter_get_test_none_multi.main = function() {
  };
  dart.fn(static_setter_get_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.static_setter_get_test_none_multi = static_setter_get_test_none_multi;
});
