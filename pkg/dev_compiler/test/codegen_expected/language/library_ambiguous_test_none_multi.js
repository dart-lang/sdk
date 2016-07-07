dart_library.library('language/library_ambiguous_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__library_ambiguous_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const library_ambiguous_test_none_multi = Object.create(null);
  const library1 = Object.create(null);
  const library2 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library_ambiguous_test_none_multi.X = class X extends core.Object {};
  library_ambiguous_test_none_multi.main = function() {
    core.print("No error expected if ambiguous definitions are not used.");
  };
  dart.fn(library_ambiguous_test_none_multi.main, VoidTodynamic());
  library1.foo = null;
  library1.bar = function() {
    return "library1.dart bar()";
  };
  dart.fn(library1.bar, VoidTodynamic());
  library1.baz = function() {
    return "library1.dart baz()";
  };
  dart.fn(library1.baz, VoidTodynamic());
  library1.bay = null;
  library1.bax = dart.typedef('bax', () => dart.functionType(core.int, [core.int, core.int]));
  library1.baw = class baw extends core.Object {};
  library2.foo = null;
  library2.foo1 = 0;
  library2.bar = function() {
    return "library2.dart bar()";
  };
  dart.fn(library2.bar, VoidTodynamic());
  library2.baz = null;
  library2.bay = function() {
    return "library2.dart bay()";
  };
  dart.fn(library2.bay, VoidTodynamic());
  library2.bax = dart.typedef('bax', () => dart.functionType(core.double, [core.int, core.int]));
  library2.baw = null;
  // Exports:
  exports.library_ambiguous_test_none_multi = library_ambiguous_test_none_multi;
  exports.library1 = library1;
  exports.library2 = library2;
});
