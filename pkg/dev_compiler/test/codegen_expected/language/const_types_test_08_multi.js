dart_library.library('language/const_types_test_08_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_types_test_08_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_types_test_08_multi = Object.create(null);
  let ClassOfint = () => (ClassOfint = dart.constFn(const_types_test_08_multi.Class$(core.int)))();
  let Class = () => (Class = dart.constFn(const_types_test_08_multi.Class$()))();
  let Superclass = () => (Superclass = dart.constFn(const_types_test_08_multi.Superclass$()))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_types_test_08_multi.use = function(x) {
  };
  dart.fn(const_types_test_08_multi.use, dynamicTodynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  let const$8;
  const_types_test_08_multi.Class$ = dart.generic(T => {
    let ClassOfT = () => (ClassOfT = dart.constFn(const_types_test_08_multi.Class$(T)))();
    let ClassOfClassOfT = () => (ClassOfClassOfT = dart.constFn(const_types_test_08_multi.Class$(ClassOfT())))();
    class Class extends core.Object {
      new() {
      }
      named() {
      }
      test() {
        const_types_test_08_multi.use(const$ || (const$ = dart.constList([], dart.dynamic)));
        const_types_test_08_multi.use(const$0 || (const$0 = dart.constList([], const_types_test_08_multi.Class)));
        const_types_test_08_multi.use(const$1 || (const$1 = dart.constList([], ClassOfint())));
        const_types_test_08_multi.use(const$2 || (const$2 = dart.const(dart.map())));
        const_types_test_08_multi.use(const$3 || (const$3 = dart.const(dart.map({}, core.String, const_types_test_08_multi.Class))));
        const_types_test_08_multi.use(const$4 || (const$4 = dart.const(dart.map({}, core.String, ClassOfint()))));
        const_types_test_08_multi.use(const$5 || (const$5 = dart.const(new const_types_test_08_multi.Class())));
        const_types_test_08_multi.use(const$6 || (const$6 = dart.const(new (ClassOfint())())));
        const_types_test_08_multi.use(dart.const(new (ClassOfClassOfT())()));
        const_types_test_08_multi.use(const$7 || (const$7 = dart.const(new const_types_test_08_multi.Class.named())));
        const_types_test_08_multi.use(const$8 || (const$8 = dart.const(new (ClassOfint()).named())));
      }
    }
    dart.addTypeTests(Class);
    dart.defineNamedConstructor(Class, 'named');
    Class[dart.implements] = () => [const_types_test_08_multi.Superclass];
    dart.setSignature(Class, {
      constructors: () => ({
        new: dart.definiteFunctionType(const_types_test_08_multi.Class$(T), []),
        named: dart.definiteFunctionType(const_types_test_08_multi.Class$(T), [])
      }),
      methods: () => ({test: dart.definiteFunctionType(dart.void, [])})
    });
    return Class;
  });
  const_types_test_08_multi.Class = Class();
  const_types_test_08_multi.Superclass$ = dart.generic(T => {
    class Superclass extends core.Object {}
    dart.addTypeTests(Superclass);
    return Superclass;
  });
  const_types_test_08_multi.Superclass = Superclass();
  const_types_test_08_multi.main = function() {
    new const_types_test_08_multi.Class().test();
    new const_types_test_08_multi.Superclass();
  };
  dart.fn(const_types_test_08_multi.main, VoidTovoid());
  // Exports:
  exports.const_types_test_08_multi = const_types_test_08_multi;
});
