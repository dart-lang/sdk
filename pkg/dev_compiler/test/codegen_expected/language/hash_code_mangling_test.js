dart_library.library('language/hash_code_mangling_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hash_code_mangling_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hash_code_mangling_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  hash_code_mangling_test.Foo = class Foo extends core.Object {
    new() {
      this.$identityHash = null;
    }
  };
  hash_code_mangling_test.main = function() {
    let foo = new hash_code_mangling_test.Foo();
    foo.$identityHash = 'fisk';
    expect$.Expect.isTrue(typeof foo.$identityHash == 'string');
    let hash = foo.hashCode;
    expect$.Expect.isTrue(typeof hash == 'number');
    expect$.Expect.isTrue(typeof foo.$identityHash == 'string');
    expect$.Expect.equals(hash, foo.hashCode);
  };
  dart.fn(hash_code_mangling_test.main, VoidTovoid());
  // Exports:
  exports.hash_code_mangling_test = hash_code_mangling_test;
});
