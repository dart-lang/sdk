dart_library.library('lib/html/private_extension_member_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__private_extension_member_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const private_extension_member_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  private_extension_member_test.main = function() {
    expect$.Expect.equals("[object DocumentFragment]", dart.toString(html.BRElement.new()[dartx.createFragment]("Hi")));
  };
  dart.fn(private_extension_member_test.main, VoidTodynamic());
  // Exports:
  exports.private_extension_member_test = private_extension_member_test;
});
