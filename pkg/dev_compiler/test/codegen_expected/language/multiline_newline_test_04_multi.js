dart_library.library('language/multiline_newline_test_04_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multiline_newline_test_04_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multiline_newline_test_04_multi = Object.create(null);
  const multiline_newline_cr = Object.create(null);
  const multiline_newline_crlf = Object.create(null);
  const multiline_newline_lf = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  multiline_newline_test_04_multi.main = function() {
    expect$.Expect.equals(4, multiline_newline_cr.constantMultilineString[dartx.length]);
    expect$.Expect.equals(4, multiline_newline_crlf.constantMultilineString[dartx.length]);
    expect$.Expect.equals(4, multiline_newline_lf.constantMultilineString[dartx.length]);
    expect$.Expect.equals(multiline_newline_cr.constantMultilineString, multiline_newline_crlf.constantMultilineString);
    expect$.Expect.equals(multiline_newline_crlf.constantMultilineString, multiline_newline_lf.constantMultilineString);
    expect$.Expect.equals(multiline_newline_lf.constantMultilineString, multiline_newline_cr.constantMultilineString);
    expect$.Expect.equals(4, multiline_newline_cr.nonConstantMultilineString[dartx.length]);
    expect$.Expect.equals(4, multiline_newline_crlf.nonConstantMultilineString[dartx.length]);
    expect$.Expect.equals(4, multiline_newline_lf.nonConstantMultilineString[dartx.length]);
    expect$.Expect.equals(multiline_newline_cr.nonConstantMultilineString, multiline_newline_crlf.nonConstantMultilineString);
    expect$.Expect.equals(multiline_newline_crlf.nonConstantMultilineString, multiline_newline_lf.nonConstantMultilineString);
    expect$.Expect.equals(multiline_newline_lf.nonConstantMultilineString, multiline_newline_cr.nonConstantMultilineString);
    let c1 = multiline_newline_cr.constantMultilineString == multiline_newline_crlf.constantMultilineString ? true : null;
    let c2 = multiline_newline_crlf.constantMultilineString == multiline_newline_lf.constantMultilineString ? true : null;
    let c3 = multiline_newline_lf.constantMultilineString == multiline_newline_cr.constantMultilineString ? true : null;
    expect$.Expect.isTrue(c1);
    expect$.Expect.isTrue(c2);
    expect$.Expect.isTrue(c3);
    let c7 = multiline_newline_cr.constantMultilineString != multiline_newline_crlf.constantMultilineString ? true : null;
    let c8 = multiline_newline_crlf.constantMultilineString != multiline_newline_lf.constantMultilineString ? true : null;
    let c9 = multiline_newline_lf.constantMultilineString != multiline_newline_cr.constantMultilineString ? true : null;
    expect$.Expect.isNull(c7);
    expect$.Expect.isNull(c8);
    expect$.Expect.isNull(c9);
    let c10 = dart.test(c7) ? 1 : 2;
  };
  dart.fn(multiline_newline_test_04_multi.main, VoidTodynamic());
  multiline_newline_cr.constantMultilineString = "a\rb\r";
  multiline_newline_cr.nonConstantMultilineString = "a\rb\r";
  multiline_newline_crlf.constantMultilineString = "a\r\nb\r\n";
  multiline_newline_crlf.nonConstantMultilineString = "a\r\nb\r\n";
  multiline_newline_lf.constantMultilineString = "a\nb\n";
  multiline_newline_lf.nonConstantMultilineString = "a\nb\n";
  // Exports:
  exports.multiline_newline_test_04_multi = multiline_newline_test_04_multi;
  exports.multiline_newline_cr = multiline_newline_cr;
  exports.multiline_newline_crlf = multiline_newline_crlf;
  exports.multiline_newline_lf = multiline_newline_lf;
});
