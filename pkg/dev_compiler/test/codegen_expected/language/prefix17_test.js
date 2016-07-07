dart_library.library('language/prefix17_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix17_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix17_test = Object.create(null);
  const library12 = Object.create(null);
  const library11 = Object.create(null);
  let Library111 = () => (Library111 = dart.constFn(library11.Library111$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix17_test.LocalClass = class LocalClass extends core.Object {};
  prefix17_test.LocalClass.static_fld = null;
  prefix17_test.main = function() {
    prefix17_test.LocalClass.static_fld = 42;
    let lc1 = new library12.Library12(5);
    let lc2 = new library12.Library12(10);
    let lc2m = new library12.Library12.other(10, 2);
    library12.Library12.static_fld = 43;
  };
  dart.fn(prefix17_test.main, VoidTovoid());
  library12.Library12 = class Library12 extends core.Object {
    new(fld) {
      this.fld = fld;
    }
    other(fld, multiplier) {
      this.fld = null;
      this.fld = dart.dsend(fld, '*', multiplier);
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
      result = dart.notNull(result) + dart.notNull(core.int._check(library11.Library11.static_fld));
      expect$.Expect.equals(10, result);
      expect$.Expect.equals(100, library11.top_level11);
      expect$.Expect.equals(200, library11.top_level_func11());
      return 3;
    }
  };
  dart.defineNamedConstructor(library12.Library12, 'other');
  dart.setSignature(library12.Library12, {
    constructors: () => ({
      new: dart.definiteFunctionType(library12.Library12, [dart.dynamic]),
      other: dart.definiteFunctionType(library12.Library12, [dart.dynamic, dart.dynamic])
    }),
    methods: () => ({func: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({static_func: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['static_func']
  });
  library12.Library12.static_fld = 4;
  library12.Library12Interface = class Library12Interface extends core.Object {};
  library12.top_level12 = 10;
  library12.top_level_func12 = function() {
    return 20;
  };
  dart.fn(library12.top_level_func12, VoidTodynamic());
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
  exports.prefix17_test = prefix17_test;
  exports.library12 = library12;
  exports.library11 = library11;
});
