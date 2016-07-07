dart_library.library('language/closure_cycles_test', null, /* Imports */[
  'dart_sdk'
], function load__closure_cycles_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const closure_cycles_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  closure_cycles_test.X = class X extends core.Object {
    new() {
      this.onX = null;
      async.Timer.run(dart.fn(() => dart.dcall(this.onX, new closure_cycles_test.Y()), VoidTovoid()));
    }
  };
  dart.setSignature(closure_cycles_test.X, {
    constructors: () => ({new: dart.definiteFunctionType(closure_cycles_test.X, [])})
  });
  closure_cycles_test.Y = class Y extends core.Object {
    new() {
      this.onY = null;
      this.heavyMemory = null;
      this.heavyMemory = core.List.new(10 * 1024 * 1024);
      if ((() => {
        let x = closure_cycles_test.Y.count;
        closure_cycles_test.Y.count = dart.notNull(x) + 1;
        return x;
      })() > 100) return;
      async.Timer.run(dart.fn(() => dart.dcall(this.onY), VoidTovoid()));
    }
  };
  dart.setSignature(closure_cycles_test.Y, {
    constructors: () => ({new: dart.definiteFunctionType(closure_cycles_test.Y, [])})
  });
  closure_cycles_test.Y.count = 0;
  closure_cycles_test.doIt = function() {
    let x = new closure_cycles_test.X();
    x.onX = dart.fn(y => {
      dart.dput(y, 'onY', dart.fn(() => {
        y;
        closure_cycles_test.doIt();
      }, VoidTodynamic()));
    }, dynamicTodynamic());
  };
  dart.fn(closure_cycles_test.doIt, VoidTovoid());
  closure_cycles_test.main = function() {
    closure_cycles_test.doIt();
  };
  dart.fn(closure_cycles_test.main, VoidTovoid());
  // Exports:
  exports.closure_cycles_test = closure_cycles_test;
});
