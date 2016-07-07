dart_library.library('language/implicit_closure1_test', null, /* Imports */[
  'dart_sdk'
], function load__implicit_closure1_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const implicit_closure1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  implicit_closure1_test.Handler = dart.typedef('Handler', () => dart.functionType(dart.dynamic, [core.bool]));
  implicit_closure1_test.Hello = class Hello extends core.Object {
    new() {
    }
    handler2(e) {
      core.print('handler2');
    }
    static handler1(e) {
      core.print('handler1');
    }
    addEventListener(s, handler, status) {
      handler(status);
    }
    static main() {
      let h = new implicit_closure1_test.Hello();
      h.addEventListener('click', implicit_closure1_test.Hello.handler1, false);
      h.addEventListener('click', dart.bind(h, 'handler2'), false);
    }
  };
  dart.setSignature(implicit_closure1_test.Hello, {
    constructors: () => ({new: dart.definiteFunctionType(implicit_closure1_test.Hello, [])}),
    methods: () => ({
      handler2: dart.definiteFunctionType(dart.void, [core.bool]),
      addEventListener: dart.definiteFunctionType(dart.void, [core.String, implicit_closure1_test.Handler, core.bool])
    }),
    statics: () => ({
      handler1: dart.definiteFunctionType(dart.void, [core.bool]),
      main: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['handler1', 'main']
  });
  implicit_closure1_test.main = function() {
    implicit_closure1_test.Hello.main();
  };
  dart.fn(implicit_closure1_test.main, VoidTodynamic());
  // Exports:
  exports.implicit_closure1_test = implicit_closure1_test;
});
