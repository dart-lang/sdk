dart_library.library('language/top_level_prefixed_declaration_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_prefixed_declaration_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_prefixed_declaration_test = Object.create(null);
  const library11 = Object.create(null);
  let Library111 = () => (Library111 = dart.constFn(library11.Library111$()))();
  let VoidToLibrary11 = () => (VoidToLibrary11 = dart.constFn(dart.definiteFunctionType(library11.Library11, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_prefixed_declaration_test.variable = null;
  top_level_prefixed_declaration_test.function = function() {
    return null;
  };
  dart.lazyFn(top_level_prefixed_declaration_test.function, () => VoidToLibrary11());
  dart.copyProperties(top_level_prefixed_declaration_test, {
    get getter() {
      return null;
    }
  });
  top_level_prefixed_declaration_test.main = function() {
    expect$.Expect.isTrue(top_level_prefixed_declaration_test.variable == null);
    expect$.Expect.isTrue(top_level_prefixed_declaration_test.function() == null);
    expect$.Expect.isTrue(top_level_prefixed_declaration_test.getter == null);
  };
  dart.fn(top_level_prefixed_declaration_test.main, VoidTodynamic());
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
  exports.top_level_prefixed_declaration_test = top_level_prefixed_declaration_test;
  exports.library11 = library11;
});
