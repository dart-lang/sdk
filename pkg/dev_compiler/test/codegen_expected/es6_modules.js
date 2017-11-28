const _root = Object.create(null);
export const es6_modules = Object.create(_root);
import { core, dart, dartx } from 'dart_sdk';
let B = () => (B = dart.constFn(es6_modules.B$()))();
let _B = () => (_B = dart.constFn(es6_modules._B$()))();
let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))();
let VoidToString = () => (VoidToString = dart.constFn(dart.fnType(core.String, [])))();
es6_modules.Callback = dart.typedef('Callback', () => dart.fnTypeFuzzy(dart.void, [], {i: core.int}));
es6_modules.A = class A extends core.Object {};
(es6_modules.A.new = function() {
}).prototype = es6_modules.A.prototype;
dart.addTypeTests(es6_modules.A);
es6_modules._A = class _A extends core.Object {};
(es6_modules._A.new = function() {
}).prototype = es6_modules._A.prototype;
dart.addTypeTests(es6_modules._A);
const _is_B_default = Symbol('_is_B_default');
es6_modules.B$ = dart.generic(T => {
  class B extends core.Object {}
  (B.new = function() {
  }).prototype = B.prototype;
  dart.addTypeTests(B);
  B.prototype[_is_B_default] = true;
  return B;
});
es6_modules.B = B();
dart.addTypeTests(es6_modules.B, _is_B_default);
const _is__B_default = Symbol('_is__B_default');
es6_modules._B$ = dart.generic(T => {
  class _B extends core.Object {}
  (_B.new = function() {
  }).prototype = _B.prototype;
  dart.addTypeTests(_B);
  _B.prototype[_is__B_default] = true;
  return _B;
});
es6_modules._B = _B();
dart.addTypeTests(es6_modules._B, _is__B_default);
es6_modules.f = function() {
};
dart.fn(es6_modules.f, VoidTodynamic());
es6_modules._f = function() {
};
dart.fn(es6_modules._f, VoidTodynamic());
dart.defineLazy(es6_modules, {
  get constant() {
    return "abc";
  },
  get finalConstant() {
    return "abc";
  },
  get lazy() {
    return dart.fn(() => {
      core.print('lazy');
      return "abc";
    }, VoidToString())();
  },
  get mutable() {
    return "abc";
  },
  set mutable(_) {},
  get lazyMutable() {
    return dart.fn(() => {
      core.print('lazyMutable');
      return "abc";
    }, VoidToString())();
  },
  set lazyMutable(_) {}
});
dart.trackLibraries("es6_modules", {
  "es6_modules.dart": es6_modules
}, null);
