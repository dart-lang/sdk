dart_library.library('language/prefix12_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix12_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix12_test = Object.create(null);
  const library11 = Object.create(null);
  let Library111Ofint = () => (Library111Ofint = dart.constFn(library11.Library111$(core.int)))();
  let Library111 = () => (Library111 = dart.constFn(library11.Library111$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix12_test.Prefix12Test = class Prefix12Test extends core.Object {
    static Test1() {
      let result = 0;
      let obj = new library11.Library11.namedConstructor(10);
      result = core.int._check(obj.fld);
      expect$.Expect.equals(10, result);
    }
    static Test2() {
      let result = 0;
      let obj = new (Library111Ofint()).namedConstructor(10);
      result = obj.fld;
      expect$.Expect.equals(10, result);
    }
  };
  dart.setSignature(prefix12_test.Prefix12Test, {
    statics: () => ({
      Test1: dart.definiteFunctionType(dart.dynamic, []),
      Test2: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['Test1', 'Test2']
  });
  prefix12_test.main = function() {
    prefix12_test.Prefix12Test.Test1();
    prefix12_test.Prefix12Test.Test2();
  };
  dart.fn(prefix12_test.main, VoidTodynamic());
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
  exports.prefix12_test = prefix12_test;
  exports.library11 = library11;
});
