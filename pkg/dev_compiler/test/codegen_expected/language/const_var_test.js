dart_library.library('language/const_var_test', null, /* Imports */[
  'dart_sdk'
], function load__const_var_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_var_test = Object.create(null);
  const const_var_helper = Object.create(null);
  let FooOfint = () => (FooOfint = dart.constFn(const_var_test.Foo$(core.int)))();
  let FooOfint$ = () => (FooOfint$ = dart.constFn(const_var_helper.Foo$(core.int)))();
  let Foo = () => (Foo = dart.constFn(const_var_test.Foo$()))();
  let Foo$ = () => (Foo$ = dart.constFn(const_var_helper.Foo$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_var_test.untypedTopLevel = 1;
  const_var_test.typedTopLevel = 2;
  const_var_test.genericTopLevel = dart.const(dart.map({}, core.String, core.String));
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  const_var_test.main = function() {
    let untypedLocal = 3;
    let typedLocal = 4;
    let genericLocal = const$ || (const$ = dart.const(dart.map({}, core.String, core.String)));
    const$0 || (const$0 = dart.constList([], dart.dynamic));
    const$1 || (const$1 = dart.const(dart.map()));
    const$2 || (const$2 = dart.constList([], core.int));
    const$3 || (const$3 = dart.const(dart.map({}, core.String, core.int)));
    const$4 || (const$4 = dart.const(new const_var_test.Foo()));
    const$5 || (const$5 = dart.const(new (FooOfint())()));
    const$6 || (const$6 = dart.const(new const_var_helper.Foo()));
    const$7 || (const$7 = dart.const(new (FooOfint$())()));
  };
  dart.fn(const_var_test.main, VoidTodynamic());
  const_var_test.Foo$ = dart.generic(E => {
    class Foo extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      constructors: () => ({new: dart.definiteFunctionType(const_var_test.Foo$(E), [])})
    });
    return Foo;
  });
  const_var_test.Foo = Foo();
  const_var_helper.Foo$ = dart.generic(E => {
    class Foo extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      constructors: () => ({new: dart.definiteFunctionType(const_var_helper.Foo$(E), [])})
    });
    return Foo;
  });
  const_var_helper.Foo = Foo$();
  // Exports:
  exports.const_var_test = const_var_test;
  exports.const_var_helper = const_var_helper;
});
