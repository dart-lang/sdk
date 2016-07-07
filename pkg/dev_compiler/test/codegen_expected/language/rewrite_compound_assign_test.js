dart_library.library('language/rewrite_compound_assign_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_compound_assign_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_compound_assign_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_compound_assign_test.global = 0;
  rewrite_compound_assign_test.Foo = class Foo extends core.Object {
    new() {
      this.field = 0;
    }
  };
  rewrite_compound_assign_test.Foo.staticField = 0;
  rewrite_compound_assign_test.field_compound1 = function(obj) {
    return dart.dput(obj, 'field', dart.dsend(dart.dload(obj, 'field'), '+', 5));
  };
  dart.fn(rewrite_compound_assign_test.field_compound1, dynamicTodynamic());
  rewrite_compound_assign_test.field_compound2 = function(obj) {
    return dart.dput(obj, 'field', dart.dsend(dart.dload(obj, 'field'), '+', 1));
  };
  dart.fn(rewrite_compound_assign_test.field_compound2, dynamicTodynamic());
  rewrite_compound_assign_test.field_compound3 = function(obj) {
    return dart.dput(obj, 'field', dart.dsend(dart.dload(obj, 'field'), '-', 1));
  };
  dart.fn(rewrite_compound_assign_test.field_compound3, dynamicTodynamic());
  rewrite_compound_assign_test.field_compound4 = function(obj) {
    return dart.dput(obj, 'field', dart.dsend(dart.dload(obj, 'field'), '*', 1));
  };
  dart.fn(rewrite_compound_assign_test.field_compound4, dynamicTodynamic());
  rewrite_compound_assign_test.static_compound1 = function() {
    return rewrite_compound_assign_test.Foo.staticField = dart.notNull(rewrite_compound_assign_test.Foo.staticField) + 5;
  };
  dart.fn(rewrite_compound_assign_test.static_compound1, VoidTodynamic());
  rewrite_compound_assign_test.static_compound2 = function() {
    return rewrite_compound_assign_test.Foo.staticField = dart.notNull(rewrite_compound_assign_test.Foo.staticField) + 1;
  };
  dart.fn(rewrite_compound_assign_test.static_compound2, VoidTodynamic());
  rewrite_compound_assign_test.static_compound3 = function() {
    return rewrite_compound_assign_test.Foo.staticField = dart.notNull(rewrite_compound_assign_test.Foo.staticField) - 1;
  };
  dart.fn(rewrite_compound_assign_test.static_compound3, VoidTodynamic());
  rewrite_compound_assign_test.static_compound4 = function() {
    return rewrite_compound_assign_test.Foo.staticField = dart.notNull(rewrite_compound_assign_test.Foo.staticField) * 1;
  };
  dart.fn(rewrite_compound_assign_test.static_compound4, VoidTodynamic());
  rewrite_compound_assign_test.global_compound1 = function() {
    return rewrite_compound_assign_test.global = dart.notNull(rewrite_compound_assign_test.global) + 5;
  };
  dart.fn(rewrite_compound_assign_test.global_compound1, VoidTodynamic());
  rewrite_compound_assign_test.global_compound2 = function() {
    return rewrite_compound_assign_test.global = dart.notNull(rewrite_compound_assign_test.global) + 1;
  };
  dart.fn(rewrite_compound_assign_test.global_compound2, VoidTodynamic());
  rewrite_compound_assign_test.global_compound3 = function() {
    return rewrite_compound_assign_test.global = dart.notNull(rewrite_compound_assign_test.global) - 1;
  };
  dart.fn(rewrite_compound_assign_test.global_compound3, VoidTodynamic());
  rewrite_compound_assign_test.global_compound4 = function() {
    return rewrite_compound_assign_test.global = dart.notNull(rewrite_compound_assign_test.global) * 1;
  };
  dart.fn(rewrite_compound_assign_test.global_compound4, VoidTodynamic());
  rewrite_compound_assign_test.local_compound1 = function(x) {
    x = dart.dsend(x, '+', 5);
    if (dart.test(dart.dsend(x, '>', 0))) {
      return x;
    }
    return dart.dsend(x, 'unary-');
  };
  dart.fn(rewrite_compound_assign_test.local_compound1, dynamicTodynamic());
  rewrite_compound_assign_test.local_compound2 = function(x) {
    x = dart.dsend(x, '+', 1);
    if (dart.test(dart.dsend(x, '>', 0))) {
      return x;
    }
    return dart.dsend(x, 'unary-');
  };
  dart.fn(rewrite_compound_assign_test.local_compound2, dynamicTodynamic());
  rewrite_compound_assign_test.local_compound3 = function(x) {
    x = dart.dsend(x, '-', 1);
    if (dart.test(dart.dsend(x, '>', 0))) {
      return x;
    }
    return dart.dsend(x, 'unary-');
  };
  dart.fn(rewrite_compound_assign_test.local_compound3, dynamicTodynamic());
  rewrite_compound_assign_test.local_compound4 = function(x) {
    x = dart.dsend(x, '*', 1);
    if (dart.test(dart.dsend(x, '>', 0))) {
      return x;
    }
    return dart.dsend(x, 'unary-');
  };
  dart.fn(rewrite_compound_assign_test.local_compound4, dynamicTodynamic());
  rewrite_compound_assign_test.main = function() {
    let obj = new rewrite_compound_assign_test.Foo();
    expect$.Expect.equals(5, rewrite_compound_assign_test.field_compound1(obj));
    expect$.Expect.equals(5, obj.field);
    expect$.Expect.equals(6, rewrite_compound_assign_test.field_compound2(obj));
    expect$.Expect.equals(6, obj.field);
    expect$.Expect.equals(5, rewrite_compound_assign_test.field_compound3(obj));
    expect$.Expect.equals(5, obj.field);
    expect$.Expect.equals(5, rewrite_compound_assign_test.field_compound4(obj));
    expect$.Expect.equals(5, obj.field);
    expect$.Expect.equals(5, rewrite_compound_assign_test.static_compound1());
    expect$.Expect.equals(5, rewrite_compound_assign_test.Foo.staticField);
    expect$.Expect.equals(6, rewrite_compound_assign_test.static_compound2());
    expect$.Expect.equals(6, rewrite_compound_assign_test.Foo.staticField);
    expect$.Expect.equals(5, rewrite_compound_assign_test.static_compound3());
    expect$.Expect.equals(5, rewrite_compound_assign_test.Foo.staticField);
    expect$.Expect.equals(5, rewrite_compound_assign_test.static_compound4());
    expect$.Expect.equals(5, rewrite_compound_assign_test.Foo.staticField);
    expect$.Expect.equals(5, rewrite_compound_assign_test.global_compound1());
    expect$.Expect.equals(5, rewrite_compound_assign_test.global);
    expect$.Expect.equals(6, rewrite_compound_assign_test.global_compound2());
    expect$.Expect.equals(6, rewrite_compound_assign_test.global);
    expect$.Expect.equals(5, rewrite_compound_assign_test.global_compound3());
    expect$.Expect.equals(5, rewrite_compound_assign_test.global);
    expect$.Expect.equals(5, rewrite_compound_assign_test.global_compound4());
    expect$.Expect.equals(5, rewrite_compound_assign_test.global);
    expect$.Expect.equals(8, rewrite_compound_assign_test.local_compound1(3));
    expect$.Expect.equals(3, rewrite_compound_assign_test.local_compound1(-8));
    expect$.Expect.equals(4, rewrite_compound_assign_test.local_compound2(3));
    expect$.Expect.equals(7, rewrite_compound_assign_test.local_compound2(-8));
    expect$.Expect.equals(2, rewrite_compound_assign_test.local_compound3(3));
    expect$.Expect.equals(9, rewrite_compound_assign_test.local_compound3(-8));
    expect$.Expect.equals(3, rewrite_compound_assign_test.local_compound4(3));
    expect$.Expect.equals(8, rewrite_compound_assign_test.local_compound4(-8));
  };
  dart.fn(rewrite_compound_assign_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_compound_assign_test = rewrite_compound_assign_test;
});
