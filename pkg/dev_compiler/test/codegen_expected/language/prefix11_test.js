dart_library.library('language/prefix11_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix11_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix11_test = Object.create(null);
  const library10 = Object.create(null);
  const library11 = Object.create(null);
  let Library111 = () => (Library111 = dart.constFn(library11.Library111$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix11_test.Prefix11Test = class Prefix11Test extends core.Object {
    static Test1() {
      let result = 0;
      let obj = new library10.Library10(1);
      result = core.int._check(obj.fld);
      expect$.Expect.equals(1, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(obj.func()));
      expect$.Expect.equals(3, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(library10.Library10.static_func()));
      expect$.Expect.equals(6, result);
      result = dart.notNull(result) + dart.notNull(library10.Library10.static_fld);
      expect$.Expect.equals(10, result);
    }
    static Test2() {
      let result = 0;
      let obj = new library11.Library11(4);
      result = core.int._check(obj.fld);
      expect$.Expect.equals(4, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(obj.func()));
      expect$.Expect.equals(7, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(library11.Library11.static_func()));
      expect$.Expect.equals(9, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(library11.Library11.static_fld));
      expect$.Expect.equals(10, result);
    }
    static Test3() {
      expect$.Expect.equals(10, library10.top_level10);
      expect$.Expect.equals(20, library10.top_level_func10());
    }
    static Test4() {
      expect$.Expect.equals(100, library11.top_level11);
      expect$.Expect.equals(200, library11.top_level_func11());
    }
  };
  dart.setSignature(prefix11_test.Prefix11Test, {
    statics: () => ({
      Test1: dart.definiteFunctionType(dart.dynamic, []),
      Test2: dart.definiteFunctionType(dart.dynamic, []),
      Test3: dart.definiteFunctionType(dart.dynamic, []),
      Test4: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['Test1', 'Test2', 'Test3', 'Test4']
  });
  prefix11_test.main = function() {
    prefix11_test.Prefix11Test.Test1();
    prefix11_test.Prefix11Test.Test2();
    prefix11_test.Prefix11Test.Test3();
    prefix11_test.Prefix11Test.Test4();
  };
  dart.fn(prefix11_test.main, VoidTodynamic());
  library10.Library10 = class Library10 extends core.Object {
    new(fld) {
      this.fld = fld;
    }
    func() {
      return 2;
    }
    static static_func() {
      let result = 0;
      let obj = new library11.Library11(4);
      result = core.int._check(obj.fld);
      expect$.Expect.equals(4, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(obj.func()));
      expect$.Expect.equals(7, result);
      result = dart.notNull(result) + dart.notNull(core.int._check(library11.Library11.static_func()));
      expect$.Expect.equals(9, result);
      result = dart.notNull(result) + dart.notNull(library11.Library11.static_fld);
      expect$.Expect.equals(10, result);
      expect$.Expect.equals(100, library11.top_level11);
      expect$.Expect.equals(200, library11.top_level_func11());
      return 3;
    }
  };
  dart.setSignature(library10.Library10, {
    constructors: () => ({new: dart.definiteFunctionType(library10.Library10, [dart.dynamic])}),
    methods: () => ({func: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({static_func: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['static_func']
  });
  library10.Library10.static_fld = 4;
  library10.top_level10 = 10;
  library10.top_level_func10 = function() {
    return 20;
  };
  dart.fn(library10.top_level_func10, VoidTodynamic());
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
  exports.prefix11_test = prefix11_test;
  exports.library10 = library10;
  exports.library11 = library11;
});
