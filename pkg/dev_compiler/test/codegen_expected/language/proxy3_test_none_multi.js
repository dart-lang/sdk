dart_library.library('language/proxy3_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__proxy3_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const proxy3_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  proxy3_test_none_multi.isFalse = core.identical(-0.0, 0);
  proxy3_test_none_multi.validProxy = proxy3_test_none_multi.isFalse ? null : core.proxy;
  proxy3_test_none_multi.invalidProxy = proxy3_test_none_multi.isFalse ? core.proxy : null;
  proxy3_test_none_multi.ValidProxy = class ValidProxy extends core.Object {};
  proxy3_test_none_multi.InvalidProxy = class InvalidProxy extends core.Object {};
  proxy3_test_none_multi.main = function() {
  };
  dart.fn(proxy3_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.proxy3_test_none_multi = proxy3_test_none_multi;
});
