dart_library.library('language/private_mixin_exception_throw_test', null, /* Imports */[
  'dart_sdk'
], function load__private_mixin_exception_throw_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const private_mixin_exception_throw_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  private_mixin_exception_throw_test._C = class _C extends core.Object {};
  private_mixin_exception_throw_test._E = class _E extends core.Object {
    throwIt() {
      return dart.throw("it");
    }
  };
  dart.setSignature(private_mixin_exception_throw_test._E, {
    methods: () => ({throwIt: dart.definiteFunctionType(dart.dynamic, [])})
  });
  private_mixin_exception_throw_test._F = class _F extends core.Object {
    throwIt() {
      return dart.throw("IT");
    }
  };
  dart.setSignature(private_mixin_exception_throw_test._F, {
    methods: () => ({throwIt: dart.definiteFunctionType(dart.dynamic, [])})
  });
  private_mixin_exception_throw_test._D = class _D extends dart.mixin(private_mixin_exception_throw_test._C, private_mixin_exception_throw_test._E, private_mixin_exception_throw_test._F) {};
  private_mixin_exception_throw_test.main = function() {
    let d = new private_mixin_exception_throw_test._D();
    try {
      d.throwIt();
    } catch (e) {
      let s = dart.stackTrace(e);
      core.print(dart.str`Exception: ${e}`);
      core.print(dart.str`Stacktrace:\n${s}`);
    }

  };
  dart.fn(private_mixin_exception_throw_test.main, VoidTodynamic());
  // Exports:
  exports.private_mixin_exception_throw_test = private_mixin_exception_throw_test;
});
