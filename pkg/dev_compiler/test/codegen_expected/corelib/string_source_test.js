dart_library.library('corelib/string_source_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_source_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_source_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_source_test.main = function() {
    let base = "𐐒";
    let strings = ["𐐒", "𐐒", core.String.fromCharCodes(JSArrayOfint().of([55297, 56338])), dart.notNull(base[dartx.get](0)) + dart.notNull(base[dartx.get](1)), dart.str`${base}`, dart.str`${base[dartx.get](0)}${base[dartx.get](1)}`, dart.str`${base[dartx.get](0)}${base[dartx.substring](1)}`, core.String.fromCharCodes(JSArrayOfint().of([66578])), ("a" + base)[dartx.substring](1), (() => {
        let _ = new core.StringBuffer();
        _.writeCharCode(55297);
        _.writeCharCode(56338);
        return _;
      })().toString(), (() => {
        let _ = new core.StringBuffer();
        _.writeCharCode(66578);
        return _;
      })().toString(), convert.JSON.decode('"𐐒"'), core.Map.as(convert.JSON.decode('{"𐐒":[]}'))[dartx.keys][dartx.first]];
    for (let string of strings) {
      core.String._check(string);
      expect$.Expect.equals(base[dartx.length], string[dartx.length]);
      expect$.Expect.equals(base, string);
      expect$.Expect.equals(dart.hashCode(base), dart.hashCode(string));
      expect$.Expect.listEquals(base[dartx.codeUnits][dartx.toList](), string[dartx.codeUnits][dartx.toList]());
    }
  };
  dart.fn(string_source_test.main, VoidTodynamic());
  // Exports:
  exports.string_source_test = string_source_test;
});
