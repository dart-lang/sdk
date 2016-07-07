dart_library.library('language/multiline_strings_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multiline_strings_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multiline_strings_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  multiline_strings_test.main = function() {
    expect$.Expect.equals('foo', 'foo');
    expect$.Expect.equals('\\\nfoo', '\\\nfoo');
    expect$.Expect.equals('\t\nfoo', '\t\nfoo');
    expect$.Expect.equals('foo', 'foo');
    expect$.Expect.equals('foo', 'foo');
    expect$.Expect.equals(' \nfoo', ' \nfoo');
    let x = ' ';
    expect$.Expect.equals(' \nfoo', dart.str`${x}\nfoo`);
    expect$.Expect.equals('foo', 'foo');
    expect$.Expect.equals('\\\\\nfoo', '\\\\\nfoo');
    expect$.Expect.equals('\\t\nfoo', '\\t\nfoo');
    expect$.Expect.equals('foo', 'foo');
    expect$.Expect.equals('foo', 'foo');
  };
  dart.fn(multiline_strings_test.main, VoidTodynamic());
  // Exports:
  exports.multiline_strings_test = multiline_strings_test;
});
