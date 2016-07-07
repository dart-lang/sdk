dart_library.library('language/switch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__switch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const switch_test = Object.create(null);
  let EnumAndintTovoid = () => (EnumAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [switch_test.Enum, core.int])))();
  let intAndintTovoid = () => (intAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int])))();
  let boolAndintTovoid = () => (boolAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.bool, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  switch_test.Switcher = class Switcher extends core.Object {
    new() {
    }
    test1(val) {
      let x = 0;
      switch (val) {
        case 1:
        {
          x = 100;
          break;
        }
        case 2:
        case 3:
        {
          x = 200;
          break;
        }
        case 4:
        default:
        {
          {
            x = 400;
            break;
          }
        }
      }
      return x;
    }
    test2(val) {
      switch (val) {
        case 1:
        {
          return 200;
        }
        default:
        {
          return 400;
        }
      }
    }
  };
  dart.setSignature(switch_test.Switcher, {
    constructors: () => ({new: dart.definiteFunctionType(switch_test.Switcher, [])}),
    methods: () => ({
      test1: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      test2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  switch_test.SwitchTest = class SwitchTest extends core.Object {
    static testMain() {
      let s = new switch_test.Switcher();
      expect$.Expect.equals(100, s.test1(1));
      expect$.Expect.equals(200, s.test1(2));
      expect$.Expect.equals(200, s.test1(3));
      expect$.Expect.equals(400, s.test1(4));
      expect$.Expect.equals(400, s.test1(5));
      expect$.Expect.equals(200, s.test2(1));
      expect$.Expect.equals(400, s.test2(2));
    }
  };
  dart.setSignature(switch_test.SwitchTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  switch_test.Enum = class Enum extends core.Object {
    new(id) {
      this.id = id;
    }
  };
  dart.setSignature(switch_test.Enum, {
    constructors: () => ({new: dart.definiteFunctionType(switch_test.Enum, [core.int])})
  });
  dart.defineLazy(switch_test.Enum, {
    get e1() {
      return dart.const(new switch_test.Enum(1));
    },
    get e2() {
      return dart.const(new switch_test.Enum(2));
    },
    get e3() {
      return dart.const(new switch_test.Enum(3));
    }
  });
  switch_test.testSwitchEnum = function(input, expect) {
    let result = null;
    switch (input) {
      case switch_test.Enum.e1:
      {
        result = 10;
        break;
      }
      case switch_test.Enum.e2:
      {
        result = 20;
        break;
      }
      case switch_test.Enum.e3:
      {
        result = 30;
        break;
      }
      default:
      {
        result = 40;
      }
    }
    expect$.Expect.equals(expect, result);
  };
  dart.fn(switch_test.testSwitchEnum, EnumAndintTovoid());
  switch_test.ic1 = 1;
  switch_test.ic2 = 2;
  switch_test.testSwitchIntExpression = function(input, expect) {
    let result = null;
    switch (input) {
      case 1 + 1:
      case switch_test.ic1 + 2:
      {
        result = 11;
        break;
      }
      case switch_test.ic2 * 2:
      case 1 * 5:
      {
        result = 21;
        break;
      }
      case switch_test.ic1[dartx['%']](switch_test.ic2) + 5:
      {
        result = 31;
        break;
      }
    }
    expect$.Expect.equals(expect, result);
  };
  dart.fn(switch_test.testSwitchIntExpression, intAndintTovoid());
  switch_test.testSwitchBool = function(input, expect) {
    let result = null;
    switch (input) {
      case true:
      {
        result = 12;
        break;
      }
      case false:
      {
        result = 22;
      }
    }
    expect$.Expect.equals(expect, result);
  };
  dart.fn(switch_test.testSwitchBool, boolAndintTovoid());
  switch_test.main = function() {
    switch_test.SwitchTest.testMain();
    switch_test.testSwitchEnum(switch_test.Enum.e1, 10);
    switch_test.testSwitchEnum(switch_test.Enum.e2, 20);
    switch_test.testSwitchEnum(switch_test.Enum.e3, 30);
    switch_test.testSwitchEnum(null, 40);
    switch_test.testSwitchIntExpression(2, 11);
    switch_test.testSwitchIntExpression(3, 11);
    switch_test.testSwitchIntExpression(4, 21);
    switch_test.testSwitchIntExpression(5, 21);
    switch_test.testSwitchIntExpression(6, 31);
    switch_test.testSwitchIntExpression(7, null);
    switch_test.testSwitchBool(true, 12);
    switch_test.testSwitchBool(false, 22);
  };
  dart.fn(switch_test.main, VoidTodynamic());
  // Exports:
  exports.switch_test = switch_test;
});
