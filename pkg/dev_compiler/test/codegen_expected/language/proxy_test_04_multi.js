dart_library.library('language/proxy_test_04_multi', null, /* Imports */[
  'dart_sdk'
], function load__proxy_test_04_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const proxy_test_04_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  proxy_test_04_multi.NonProxy = class NonProxy extends core.Object {};
  proxy_test_04_multi.Proxy = class Proxy extends core.Object {};
  proxy_test_04_multi.alias = core.proxy;
  proxy_test_04_multi.AliasProxy = class AliasProxy extends core.Object {};
  proxy_test_04_multi.main = function() {
    try {
      dart.dsend(new proxy_test_04_multi.Proxy(), 'foo');
    } catch (e) {
    }

  };
  dart.fn(proxy_test_04_multi.main, VoidTodynamic());
  // Exports:
  exports.proxy_test_04_multi = proxy_test_04_multi;
});
