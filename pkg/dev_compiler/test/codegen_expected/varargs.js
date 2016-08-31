define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const varargs = Object.create(null);
  const src__varargs = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  varargs.varargsTest = function(x, ...others) {
    let args = [1, others];
    dart.dcall(x, ...args);
  };
  dart.fn(varargs.varargsTest, dynamicAnddynamicTodynamic());
  varargs.varargsTest2 = function(x, ...others) {
    let args = [1, others];
    dart.dcall(x, ...args);
  };
  dart.fn(varargs.varargsTest2, dynamicAnddynamicTodynamic());
  src__varargs._Rest = class _Rest extends core.Object {
    new() {
    }
  };
  dart.setSignature(src__varargs._Rest, {
    constructors: () => ({new: dart.definiteFunctionType(src__varargs._Rest, [])})
  });
  src__varargs.rest = dart.const(new src__varargs._Rest());
  src__varargs.spread = function(args) {
    dart.throw(new core.StateError('The spread function cannot be called, ' + 'it should be compiled away.'));
  };
  dart.fn(src__varargs.spread, dynamicTodynamic());
  // Exports:
  return {
    varargs: varargs,
    src__varargs: src__varargs
  };
});
