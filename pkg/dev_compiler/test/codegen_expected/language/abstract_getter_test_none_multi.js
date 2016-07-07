dart_library.library('language/abstract_getter_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__abstract_getter_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const abstract_getter_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  abstract_getter_test_none_multi.Foo = class Foo extends core.Object {};
  abstract_getter_test_none_multi.Bar = class Bar extends core.Object {};
  abstract_getter_test_none_multi.noMethod = function(e) {
    return core.NoSuchMethodError.is(e);
  };
  dart.fn(abstract_getter_test_none_multi.noMethod, dynamicTodynamic());
  abstract_getter_test_none_multi.checkIt = function(f) {
  };
  dart.fn(abstract_getter_test_none_multi.checkIt, dynamicTodynamic());
  abstract_getter_test_none_multi.main = function() {
    abstract_getter_test_none_multi.checkIt(new abstract_getter_test_none_multi.Foo());
    abstract_getter_test_none_multi.checkIt(new abstract_getter_test_none_multi.Bar());
  };
  dart.fn(abstract_getter_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.abstract_getter_test_none_multi = abstract_getter_test_none_multi;
});
