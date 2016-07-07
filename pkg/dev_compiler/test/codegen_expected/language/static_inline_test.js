dart_library.library('language/static_inline_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_inline_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_inline_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  static_inline_test.StringScanner = class StringScanner extends core.Object {
    new() {
      this.byteOffset = -1;
    }
    nextByte(foo) {
      if (dart.test(foo)) return -2;
      return static_inline_test.StringScanner.charAt((this.byteOffset = dart.notNull(this.byteOffset) + 1));
    }
    static charAt(index) {
      return dart.notNull(static_inline_test.StringScanner.string[dartx.length]) > dart.notNull(core.num._check(index)) ? static_inline_test.StringScanner.string[dartx.codeUnitAt](core.int._check(index)) : -1;
    }
  };
  dart.setSignature(static_inline_test.StringScanner, {
    methods: () => ({nextByte: dart.definiteFunctionType(core.int, [dart.dynamic])}),
    statics: () => ({charAt: dart.definiteFunctionType(core.int, [dart.dynamic])}),
    names: ['charAt']
  });
  static_inline_test.StringScanner.string = null;
  static_inline_test.main = function() {
    let scanner = new static_inline_test.StringScanner();
    static_inline_test.StringScanner.string = 'az9';
    expect$.Expect.equals(97, scanner.nextByte(false));
    expect$.Expect.equals(122, scanner.nextByte(false));
    expect$.Expect.equals(57, scanner.nextByte(false));
    expect$.Expect.equals(-1, scanner.nextByte(false));
  };
  dart.fn(static_inline_test.main, VoidTovoid());
  // Exports:
  exports.static_inline_test = static_inline_test;
});
