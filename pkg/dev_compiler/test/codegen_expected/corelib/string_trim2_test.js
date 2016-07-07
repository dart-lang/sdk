dart_library.library('corelib/string_trim2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_trim2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_trim2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_trim2_test.WHITESPACE = dart.constList([9, 10, 11, 12, 13, 32, 133, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288, 8232, 8233, 65279], core.int);
  string_trim2_test.main = function() {
    for (let ws of string_trim2_test.WHITESPACE) {
      let name = ws[dartx.toRadixString](16);
      let c = core.String.fromCharCode(ws);
      expect$.Expect.equals("", c[dartx.trim](), dart.str`${name}`);
      expect$.Expect.equals("a", ("a" + c)[dartx.trim](), dart.str`a-${name}`);
      expect$.Expect.equals("a", (c + "a")[dartx.trim](), dart.str`${name}-a`);
      expect$.Expect.equals("a", (c + c + "a" + c + c)[dartx.trim](), dart.str`${name} around`);
      expect$.Expect.equals("a" + c + "a", (c + c + "a" + c + "a" + c + c)[dartx.trim](), dart.str`${name} many`);
    }
    expect$.Expect.equals("", core.String.fromCharCodes(string_trim2_test.WHITESPACE)[dartx.trim](), "ALL");
  };
  dart.fn(string_trim2_test.main, VoidTodynamic());
  // Exports:
  exports.string_trim2_test = string_trim2_test;
});
