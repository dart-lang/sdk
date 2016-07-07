dart_library.library('language/enum_mirror_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__enum_mirror_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const enum_mirror_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  enum_mirror_test.Foo = class Foo extends core.Object {
    new(index) {
      this.index = index;
    }
    toString() {
      return {
        0: "Foo.BAR",
        1: "Foo.BAZ"
      }[this.index];
    }
  };
  enum_mirror_test.Foo.BAR = dart.const(new enum_mirror_test.Foo(0));
  enum_mirror_test.Foo.BAZ = dart.const(new enum_mirror_test.Foo(1));
  enum_mirror_test.Foo.values = dart.constList([enum_mirror_test.Foo.BAR, enum_mirror_test.Foo.BAZ], enum_mirror_test.Foo);
  let const$;
  enum_mirror_test.main = function() {
    expect$.Expect.equals('Foo.BAR', enum_mirror_test.Foo.BAR.toString());
    let name = mirrors.reflect(enum_mirror_test.Foo.BAR).invoke(const$ || (const$ = dart.const(core.Symbol.new('toString'))), []).reflectee;
    expect$.Expect.equals('Foo.BAR', name);
  };
  dart.fn(enum_mirror_test.main, VoidTodynamic());
  // Exports:
  exports.enum_mirror_test = enum_mirror_test;
});
