dart_library.library('language/proxy_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__proxy_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const proxy_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  proxy_test_none_multi.NonProxy = class NonProxy extends core.Object {};
  proxy_test_none_multi.Proxy = class Proxy extends core.Object {};
  proxy_test_none_multi.alias = core.proxy;
  proxy_test_none_multi.AliasProxy = class AliasProxy extends core.Object {};
  proxy_test_none_multi.main = function() {
  };
  dart.fn(proxy_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.proxy_test_none_multi = proxy_test_none_multi;
});
