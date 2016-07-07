dart_library.library('language/library_same_name_used_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library_same_name_used_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library_same_name_used_test = Object.create(null);
  const library_same_name_used_lib1 = Object.create(null);
  const library_same_name_used_lib2 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToX = () => (VoidToX = dart.constFn(dart.definiteFunctionType(library_same_name_used_lib1.X, [])))();
  library_same_name_used_test.main = function() {
    let x = library_same_name_used_lib1.makeX();
    expect$.Expect.equals('lib2.X', dart.str`${x}`);
  };
  dart.fn(library_same_name_used_test.main, VoidTodynamic());
  library_same_name_used_lib1.X = class X extends core.Object {};
  library_same_name_used_lib1.makeX = function() {
    return new library_same_name_used_lib2.X();
  };
  dart.fn(library_same_name_used_lib1.makeX, VoidToX());
  library_same_name_used_lib2.X = class X extends core.Object {
    new() {
    }
    toString() {
      return 'lib2.X';
    }
  };
  library_same_name_used_lib2.X[dart.implements] = () => [library_same_name_used_lib1.X];
  dart.setSignature(library_same_name_used_lib2.X, {
    constructors: () => ({new: dart.definiteFunctionType(library_same_name_used_lib2.X, [])})
  });
  // Exports:
  exports.library_same_name_used_test = library_same_name_used_test;
  exports.library_same_name_used_lib1 = library_same_name_used_lib1;
  exports.library_same_name_used_lib2 = library_same_name_used_lib2;
});
