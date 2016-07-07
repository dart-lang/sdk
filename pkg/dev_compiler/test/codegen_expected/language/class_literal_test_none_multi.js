dart_library.library('language/class_literal_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__class_literal_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const class_literal_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_literal_test_none_multi.Class = class Class extends core.Object {
    static fisk() {
      return 42;
    }
  };
  dart.setSignature(class_literal_test_none_multi.Class, {
    statics: () => ({fisk: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['fisk']
  });
  class_literal_test_none_multi.foo = function(x) {
  };
  dart.fn(class_literal_test_none_multi.foo, dynamicTodynamic());
  class_literal_test_none_multi.main = function() {
    expect$.Expect.equals(42, class_literal_test_none_multi.Class.fisk());
    expect$.Expect.equals(null, class_literal_test_none_multi.foo(class_literal_test_none_multi.Class.fisk()));
    dart.wrapType(class_literal_test_none_multi.Class);
    let x = dart.wrapType(class_literal_test_none_multi.Class);
    class_literal_test_none_multi.foo(dart.wrapType(class_literal_test_none_multi.Class));
    expect$.Expect.isFalse(dart.wrapType(class_literal_test_none_multi.Class) == null);
    expect$.Expect.notEquals(dart.wrapType(class_literal_test_none_multi.Class), "Class");
    expect$.Expect.isTrue(typeof dart.wrapType(class_literal_test_none_multi.Class).toString() == 'string');
    let y = dart.wrapType(class_literal_test_none_multi.Class);
    expect$.Expect.isTrue(typeof y.toString() == 'string');
  };
  dart.fn(class_literal_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.class_literal_test_none_multi = class_literal_test_none_multi;
});
