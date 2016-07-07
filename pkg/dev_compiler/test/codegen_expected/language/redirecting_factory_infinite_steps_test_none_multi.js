dart_library.library('language/redirecting_factory_infinite_steps_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__redirecting_factory_infinite_steps_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const redirecting_factory_infinite_steps_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  redirecting_factory_infinite_steps_test_none_multi.Bar = class Bar extends core.Object {};
  redirecting_factory_infinite_steps_test_none_multi.Foo = class Foo extends redirecting_factory_infinite_steps_test_none_multi.Bar {};
  redirecting_factory_infinite_steps_test_none_multi.main = function() {
    new redirecting_factory_infinite_steps_test_none_multi.Foo();
  };
  dart.fn(redirecting_factory_infinite_steps_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.redirecting_factory_infinite_steps_test_none_multi = redirecting_factory_infinite_steps_test_none_multi;
});
