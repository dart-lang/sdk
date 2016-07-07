dart_library.library('corelib/uri_base_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__uri_base_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const uri_base_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_base_test.main = function() {
    try {
      let base = core.Uri.base;
      expect$.Expect.isTrue(core.Uri.base.scheme == "file" || core.Uri.base.scheme == "http");
    } catch (e) {
      if (core.UnsupportedError.is(e)) {
        expect$.Expect.isTrue(dart.toString(e)[dartx.contains]("'Uri.base' is not supported"));
      } else
        throw e;
    }

  };
  dart.fn(uri_base_test.main, VoidTodynamic());
  // Exports:
  exports.uri_base_test = uri_base_test;
});
