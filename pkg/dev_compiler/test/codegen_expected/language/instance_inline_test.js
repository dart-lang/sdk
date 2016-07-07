dart_library.library('language/instance_inline_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instance_inline_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instance_inline_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  instance_inline_test.StringScanner = class StringScanner extends core.Object {
    new(string) {
      this.string = string;
      this.byteOffset = -1;
    }
    nextByte() {
      return this.charAt((this.byteOffset = dart.notNull(this.byteOffset) + 1));
    }
    charAt(index) {
      return dart.notNull(this.string[dartx.length]) > dart.notNull(core.num._check(index)) ? this.string[dartx.codeUnitAt](core.int._check(index)) : -1;
    }
  };
  dart.setSignature(instance_inline_test.StringScanner, {
    constructors: () => ({new: dart.definiteFunctionType(instance_inline_test.StringScanner, [core.String])}),
    methods: () => ({
      nextByte: dart.definiteFunctionType(core.int, []),
      charAt: dart.definiteFunctionType(core.int, [dart.dynamic])
    })
  });
  instance_inline_test.main = function() {
    let scanner = new instance_inline_test.StringScanner('az9');
    expect$.Expect.equals(97, scanner.nextByte());
    expect$.Expect.equals(122, scanner.nextByte());
    expect$.Expect.equals(57, scanner.nextByte());
    expect$.Expect.equals(-1, scanner.nextByte());
  };
  dart.fn(instance_inline_test.main, VoidTovoid());
  // Exports:
  exports.instance_inline_test = instance_inline_test;
});
