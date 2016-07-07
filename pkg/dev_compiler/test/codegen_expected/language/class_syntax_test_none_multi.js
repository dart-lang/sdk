dart_library.library('language/class_syntax_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__class_syntax_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const class_syntax_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_syntax_test_none_multi.main = function() {
    new class_syntax_test_none_multi.ClassSyntaxTest();
  };
  dart.fn(class_syntax_test_none_multi.main, VoidTodynamic());
  class_syntax_test_none_multi.ClassSyntaxTest = class ClassSyntaxTest extends core.Object {};
  // Exports:
  exports.class_syntax_test_none_multi = class_syntax_test_none_multi;
});
