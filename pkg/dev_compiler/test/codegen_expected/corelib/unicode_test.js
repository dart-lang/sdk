dart_library.library('corelib/unicode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unicode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unicode_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unicode_test.UnicodeTest = class UnicodeTest extends core.Object {
    static testMain() {
      let lowerStrasse = core.String.fromCharCodes(JSArrayOfint().of([115, 116, 114, 97, 223, 101]));
      expect$.Expect.equals("STRASSE", lowerStrasse[dartx.toUpperCase]());
    }
  };
  dart.setSignature(unicode_test.UnicodeTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  unicode_test.main = function() {
    unicode_test.UnicodeTest.testMain();
  };
  dart.fn(unicode_test.main, VoidTodynamic());
  // Exports:
  exports.unicode_test = unicode_test;
});
