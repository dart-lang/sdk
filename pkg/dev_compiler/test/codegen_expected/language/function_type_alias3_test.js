dart_library.library('language/function_type_alias3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_type_alias3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_type_alias3_test = Object.create(null);
  const library11 = Object.create(null);
  let F = () => (F = dart.constFn(function_type_alias3_test.F$()))();
  let A = () => (A = dart.constFn(function_type_alias3_test.A$()))();
  let Library111Ofbool = () => (Library111Ofbool = dart.constFn(library11.Library111$(core.bool)))();
  let AOfLibrary111Ofbool = () => (AOfLibrary111Ofbool = dart.constFn(function_type_alias3_test.A$(Library111Ofbool())))();
  let Library111Ofint = () => (Library111Ofint = dart.constFn(library11.Library111$(core.int)))();
  let AOfLibrary111Ofint = () => (AOfLibrary111Ofint = dart.constFn(function_type_alias3_test.A$(Library111Ofint())))();
  let FOfbool = () => (FOfbool = dart.constFn(function_type_alias3_test.F$(core.bool)))();
  let FOfint = () => (FOfint = dart.constFn(function_type_alias3_test.F$(core.int)))();
  let Library111 = () => (Library111 = dart.constFn(library11.Library111$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_type_alias3_test.F$ = dart.generic(Library111 => {
    const F = dart.typedef('F', () => dart.functionType(library11.Library111$(Library111), [library11.Library111$(Library111), Library111]));
    return F;
  });
  function_type_alias3_test.F = F();
  function_type_alias3_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(a, b) {
        T._check(a);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(T, [T, core.bool])})
    });
    return A;
  });
  function_type_alias3_test.A = A();
  function_type_alias3_test.main = function() {
    let a = new (AOfLibrary111Ofbool())();
    let b = new (AOfLibrary111Ofint())();
    expect$.Expect.isTrue(function_type_alias3_test.F.is(dart.bind(a, 'foo')));
    expect$.Expect.isTrue(FOfbool().is(dart.bind(a, 'foo')));
    expect$.Expect.isTrue(!FOfint().is(dart.bind(a, 'foo')));
    expect$.Expect.isTrue(function_type_alias3_test.F.is(dart.bind(b, 'foo')));
    expect$.Expect.isTrue(!FOfbool().is(dart.bind(b, 'foo')));
    expect$.Expect.isTrue(!FOfint().is(dart.bind(a, 'foo')));
  };
  dart.fn(function_type_alias3_test.main, VoidTodynamic());
  library11.Library11 = class Library11 extends core.Object {
    new(fld) {
      this.fld = fld;
    }
    namedConstructor(fld) {
      this.fld = fld;
    }
    func() {
      return 3;
    }
    static static_func() {
      return 2;
    }
  };
  dart.defineNamedConstructor(library11.Library11, 'namedConstructor');
  dart.setSignature(library11.Library11, {
    constructors: () => ({
      new: dart.definiteFunctionType(library11.Library11, [dart.dynamic]),
      namedConstructor: dart.definiteFunctionType(library11.Library11, [dart.dynamic])
    }),
    methods: () => ({func: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({static_func: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['static_func']
  });
  library11.Library11.static_fld = 1;
  library11.Library111$ = dart.generic(T => {
    class Library111 extends core.Object {
      namedConstructor(fld) {
        this.fld = fld;
      }
    }
    dart.addTypeTests(Library111);
    dart.defineNamedConstructor(Library111, 'namedConstructor');
    dart.setSignature(Library111, {
      constructors: () => ({namedConstructor: dart.definiteFunctionType(library11.Library111$(T), [T])})
    });
    return Library111;
  });
  library11.Library111 = Library111();
  library11.top_level11 = 100;
  library11.top_level_func11 = function() {
    return 200;
  };
  dart.fn(library11.top_level_func11, VoidTodynamic());
  // Exports:
  exports.function_type_alias3_test = function_type_alias3_test;
  exports.library11 = library11;
});
