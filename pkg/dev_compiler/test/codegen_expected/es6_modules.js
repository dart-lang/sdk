export const es6_modules = Object.create(null);
import { core, dart, dartx } from 'dart_sdk';
let B = () => (B = dart.constFn(es6_modules.B$()))();
let _B = () => (_B = dart.constFn(es6_modules._B$()))();
let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
es6_modules.Callback = dart.typedef('Callback', () => dart.functionType(dart.void, [], {i: core.int}));
es6_modules.A = class A extends core.Object {};
es6_modules._A = class _A extends core.Object {};
es6_modules.B$ = dart.generic(T => {
  class B extends core.Object {}
  dart.addTypeTests(B);
  return B;
});
es6_modules.B = B();
es6_modules._B$ = dart.generic(T => {
  class _B extends core.Object {}
  dart.addTypeTests(_B);
  return _B;
});
es6_modules._B = _B();
es6_modules.f = function() {
};
dart.fn(es6_modules.f, VoidTodynamic());
es6_modules._f = function() {
};
dart.fn(es6_modules._f, VoidTodynamic());
es6_modules.constant = "abc";
es6_modules.finalConstant = "abc";
dart.defineLazy(es6_modules, {
  get lazy() {
    return dart.fn(() => {
      core.print('lazy');
      return "abc";
    }, VoidToString())();
  }
});
es6_modules.mutable = "abc";
dart.defineLazy(es6_modules, {
  get lazyMutable() {
    return dart.fn(() => {
      core.print('lazyMutable');
      return "abc";
    }, VoidToString())();
  },
  set lazyMutable(_) {}
});
