dart_library.library('language/dangling_else_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dangling_else_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dangling_else_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dangling_else_test.nestedIf1 = function(notTrue) {
    if (dart.test(notTrue)) return 'bad input';
    if (dart.test(notTrue)) {
      if (dart.test(notTrue)) {
        return 'bad';
      }
    } else {
      return 'good';
    }
    return 'bug';
  };
  dart.fn(dangling_else_test.nestedIf1, dynamicTodynamic());
  dangling_else_test.nestedIf2 = function(notTrue) {
    if (dart.test(notTrue)) return 'bad input';
    if (dart.test(notTrue)) {
      if (dart.test(notTrue)) {
        return 'bad';
      } else {
        if (dart.test(notTrue)) {
          return 'bad';
        }
      }
    } else {
      return 'good';
    }
    return 'bug';
  };
  dart.fn(dangling_else_test.nestedIf2, dynamicTodynamic());
  dangling_else_test.nestedWhile = function(notTrue) {
    if (dart.test(notTrue)) return 'bad input';
    if (dart.test(notTrue)) {
      while (dart.test(notTrue)) {
        if (dart.test(notTrue)) {
          return 'bad';
        }
      }
    } else {
      return 'good';
    }
    return 'bug';
  };
  dart.fn(dangling_else_test.nestedWhile, dynamicTodynamic());
  dangling_else_test.nestedFor = function(notTrue) {
    if (dart.test(notTrue)) return 'bad input';
    if (dart.test(notTrue)) {
      for (let i = 0; i < 3; i++) {
        if (i == 0) {
          return 'bad';
        }
      }
    } else {
      return 'good';
    }
    return 'bug';
  };
  dart.fn(dangling_else_test.nestedFor, dynamicTodynamic());
  dangling_else_test.nestedLabeledStatement = function(notTrue) {
    if (dart.test(notTrue)) return 'bad input';
    if (dart.test(notTrue)) {
      label:
        if (dart.test(notTrue)) {
          break label;
        }
    } else {
      return 'good';
    }
    return 'bug';
  };
  dart.fn(dangling_else_test.nestedLabeledStatement, dynamicTodynamic());
  dangling_else_test.main = function() {
    expect$.Expect.equals('good', dangling_else_test.nestedIf1(false));
    expect$.Expect.equals('good', dangling_else_test.nestedIf2(false));
    expect$.Expect.equals('good', dangling_else_test.nestedWhile(false));
    expect$.Expect.equals('good', dangling_else_test.nestedFor(false));
    expect$.Expect.equals('good', dangling_else_test.nestedLabeledStatement(false));
  };
  dart.fn(dangling_else_test.main, VoidTodynamic());
  // Exports:
  exports.dangling_else_test = dangling_else_test;
});
