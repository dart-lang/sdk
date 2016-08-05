dart_library.library('language/regress_21016_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_21016_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_21016_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _boo = Symbol('_boo');
  regress_21016_test.A = class A extends core.Object {
    new() {
      this[_boo] = 22;
    }
    get boo() {
      return this[_boo];
      return 1;
    }
  };
  const _bar = Symbol('_bar');
  regress_21016_test.B = class B extends core.Object {
    new() {
      this[_bar] = 42;
    }
    get boo() {
      return this[_bar];
      return 1;
    }
  };
  regress_21016_test.Holder = class Holder extends core.Object {
    tearMe(x) {
      return dart.dload(x, 'boo');
    }
  };
  dart.setSignature(regress_21016_test.Holder, {
    methods: () => ({tearMe: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  dart.defineLazy(regress_21016_test, {
    get list() {
      return [];
    },
    set list(_) {}
  });
  regress_21016_test.main = function() {
    let holder = new regress_21016_test.Holder();
    let hide = dart.fn(X => X, dynamicTodynamic())(dart.bind(holder, 'tearMe'));
    dart.dcall(hide, new regress_21016_test.A());
    regress_21016_test.list[dartx.add](dart.bind(holder, 'tearMe'));
    let x = regress_21016_test.list[dartx.get](0);
    dart.dcall(x, new regress_21016_test.B());
  };
  dart.fn(regress_21016_test.main, VoidTodynamic());
  // Exports:
  exports.regress_21016_test = regress_21016_test;
});
