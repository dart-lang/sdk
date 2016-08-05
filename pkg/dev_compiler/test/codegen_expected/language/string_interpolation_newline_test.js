dart_library.library('language/string_interpolation_newline_test', null, /* Imports */[
  'dart_sdk'
], function load__string_interpolation_newline_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const string_interpolation_newline_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_interpolation_newline_test.main = function() {
    let expected = '[[{{}: {}}]]';
    let a = dart.str`${JSArrayOfString().of([dart.str`${JSArrayOfString().of([dart.str`${dart.map({[dart.str`${dart.map()}`]: dart.map()}, core.String, core.Map)}`])}`])}`;
    let b = dart.str`${JSArrayOfString().of([dart.str`${JSArrayOfString().of([dart.str`${dart.map({[dart.str`${dart.map()}`]: dart.map()}, core.String, core.Map)}`])}`])}`;
    let c = dart.str`${JSArrayOfString().of([dart.str`${JSArrayOfString().of([dart.str`${dart.map({[dart.str`${dart.map()}`]: dart.map()}, core.String, core.Map)}`])}`])}`;
    if (expected != a) dart.throw(dart.str`expecteda: ${expected} != ${a}`);
    if (a != b) dart.throw(dart.str`ab: ${a} != ${b}`);
    if (b != c) dart.throw(dart.str`bc: ${b} != ${c}`);
    core.print(dart.str`${a}${b}${c}`);
  };
  dart.fn(string_interpolation_newline_test.main, VoidTodynamic());
  // Exports:
  exports.string_interpolation_newline_test = string_interpolation_newline_test;
});
