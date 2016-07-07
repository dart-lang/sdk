dart_library.library('language/switch8_test', null, /* Imports */[
  'dart_sdk'
], function load__switch8_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const switch8_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  switch8_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(switch8_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(switch8_test.A, [])})
  });
  let const$;
  switch8_test.main = function() {
    switch (core.List.new(1)[dartx.get](0)) {
      case const$ || (const$ = dart.const(new switch8_test.A())):
      {
        dart.throw('Test failed');
      }
    }
  };
  dart.fn(switch8_test.main, VoidTodynamic());
  // Exports:
  exports.switch8_test = switch8_test;
});
