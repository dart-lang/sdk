dart_library.library('corelib/regexp/default_arguments_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__default_arguments_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const default_arguments_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_arguments_test.main = function() {
    default_arguments_test.testCaseSensitive();
    default_arguments_test.testMultiLine();
  };
  dart.fn(default_arguments_test.main, VoidTodynamic());
  default_arguments_test.testCaseSensitive = function() {
    let r1 = core.RegExp.new('foo');
    let r2 = core.RegExp.new('foo', {caseSensitive: true});
    let r3 = core.RegExp.new('foo', {caseSensitive: false});
    let r4 = core.RegExp.new('foo', {caseSensitive: null});
    expect$.Expect.isNull(r1.firstMatch('Foo'), "r1.firstMatch('Foo')");
    expect$.Expect.isNull(r2.firstMatch('Foo'), "r2.firstMatch('Foo')");
    expect$.Expect.isNotNull(r3.firstMatch('Foo'), "r3.firstMatch('Foo')");
    expect$.Expect.isNotNull(r4.firstMatch('Foo'), "r4.firstMatch('Foo')");
  };
  dart.fn(default_arguments_test.testCaseSensitive, VoidTodynamic());
  default_arguments_test.testMultiLine = function() {
    let r1 = core.RegExp.new('^foo$');
    let r2 = core.RegExp.new('^foo$', {multiLine: true});
    let r3 = core.RegExp.new('^foo$', {multiLine: false});
    let r4 = core.RegExp.new('^foo$', {multiLine: null});
    expect$.Expect.isNull(r1.firstMatch('\nfoo\n'), "r1.firstMatch('\\nfoo\\n')");
    expect$.Expect.isNotNull(r2.firstMatch('\nfoo\n'), "r2.firstMatch('\\nfoo\\n')");
    expect$.Expect.isNull(r3.firstMatch('\nfoo\n'), "r3.firstMatch('\\nfoo\\n')");
    expect$.Expect.isNull(r4.firstMatch('\nfoo\n'), "r4.firstMatch('\\nfoo\\n')");
  };
  dart.fn(default_arguments_test.testMultiLine, VoidTodynamic());
  // Exports:
  exports.default_arguments_test = default_arguments_test;
});
