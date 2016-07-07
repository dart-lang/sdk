dart_library.library('language/interface_inherit_field_test', null, /* Imports */[
  'dart_sdk'
], function load__interface_inherit_field_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const interface_inherit_field_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  interface_inherit_field_test.IA = class IA extends core.Object {
    new() {
      this.foo = null;
    }
  };
  interface_inherit_field_test.IB = class IB extends core.Object {
    new() {
      this.foo = null;
    }
  };
  interface_inherit_field_test.IB[dart.implements] = () => [interface_inherit_field_test.IA];
  const _f = Symbol('_f');
  interface_inherit_field_test.B = class B extends core.Object {
    new() {
      this[_f] = 123;
    }
    get foo() {
      return this[_f];
    }
  };
  interface_inherit_field_test.B[dart.implements] = () => [interface_inherit_field_test.IB];
  interface_inherit_field_test.main = function() {
    let b = new interface_inherit_field_test.B();
    core.print(dart.str`b.foo = ${b.foo}`);
  };
  dart.fn(interface_inherit_field_test.main, VoidTodynamic());
  // Exports:
  exports.interface_inherit_field_test = interface_inherit_field_test;
});
