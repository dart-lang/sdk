dart_library.library('corelib/iterable_empty_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_empty_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_empty_test = Object.create(null);
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicToString = () => (dynamicAnddynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic, dart.dynamic])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicToList = () => (dynamicToList = dart.constFn(dart.definiteFunctionType(core.List, [dart.dynamic])))();
  let dynamicAnddynamic__Todynamic = () => (dynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic], [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  iterable_empty_test.main = function() {
    function testEmpty(name, it, depth) {
      if (depth === void 0) depth = 2;
      expect$.Expect.isTrue(dart.dload(it, 'isEmpty'), core.String._check(name));
      expect$.Expect.isFalse(dart.dload(it, 'isNotEmpty'), core.String._check(name));
      expect$.Expect.equals(0, dart.dload(it, 'length'), core.String._check(name));
      expect$.Expect.isFalse(dart.dsend(it, 'contains', null), core.String._check(name));
      expect$.Expect.isFalse(dart.dsend(it, 'any', dart.fn(x => true, dynamicTobool())), core.String._check(name));
      expect$.Expect.isTrue(dart.dsend(it, 'every', dart.fn(x => false, dynamicTobool())), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dload(it, 'first'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dload(it, 'last'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dload(it, 'single'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dsend(it, 'elementAt', 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dsend(it, 'reduce', dart.fn((a, b) => a, dynamicAnddynamicTodynamic())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.throws(dart.fn(() => dart.dsend(it, 'singleWhere', dart.fn(_ => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()), core.String._check(name));
      expect$.Expect.equals(42, dart.dsend(it, 'fold', 42, dart.fn((a, b) => "not 42", dynamicAnddynamicToString())), core.String._check(name));
      expect$.Expect.equals(42, dart.dsend(it, 'firstWhere', dart.fn(v => true, dynamicTobool()), {orElse: dart.fn(() => 42, VoidToint())}), core.String._check(name));
      expect$.Expect.equals(42, dart.dsend(it, 'lastWhere', dart.fn(v => true, dynamicTobool()), {orElse: dart.fn(() => 42, VoidToint())}), core.String._check(name));
      expect$.Expect.equals("", dart.dsend(it, 'join', "separator"), core.String._check(name));
      expect$.Expect.equals("()", dart.toString(it), core.String._check(name));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(it, 'toList')), core.String._check(name));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(it, 'toList', {growable: false})), core.String._check(name));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(it, 'toList', {growable: true})), core.String._check(name));
      expect$.Expect.equals(0, dart.dload(dart.dsend(it, 'toSet'), 'length'), core.String._check(name));
      dart.dsend(it, 'forEach', dart.fn(v => dart.throw(v), dynamicTodynamic()));
      for (let v of core.Iterable._check(it)) {
        dart.throw(v);
      }
      if (dart.test(dart.dsend(depth, '>', 0))) {
        testEmpty(dart.str`${name}-map`, dart.dsend(it, 'map', dart.fn(x => x, dynamicTodynamic())), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-where`, dart.dsend(it, 'where', dart.fn(x => true, dynamicTobool())), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-expand`, dart.dsend(it, 'expand', dart.fn(x => [x], dynamicToList())), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-skip`, dart.dsend(it, 'skip', 1), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-take`, dart.dsend(it, 'take', 2), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-skipWhile`, dart.dsend(it, 'skipWhile', dart.fn(v => false, dynamicTobool())), dart.dsend(depth, '-', 1));
        testEmpty(dart.str`${name}-takeWhile`, dart.dsend(it, 'takeWhile', dart.fn(v => true, dynamicTobool())), dart.dsend(depth, '-', 1));
      }
    }
    dart.fn(testEmpty, dynamicAnddynamic__Todynamic());
    function testType(name, it, depth) {
      if (depth === void 0) depth = 2;
      expect$.Expect.isTrue(IterableOfint().is(it), core.String._check(name));
      expect$.Expect.isFalse(IterableOfString().is(it), core.String._check(name));
      if (dart.test(dart.dsend(depth, '>', 0))) {
        testType(dart.str`${name}-where`, dart.dsend(it, 'where', dart.fn(_ => true, dynamicTobool())), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-skip`, dart.dsend(it, 'skip', 1), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-take`, dart.dsend(it, 'take', 1), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-skipWhile`, dart.dsend(it, 'skipWhile', dart.fn(_ => false, dynamicTobool())), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-takeWhile`, dart.dsend(it, 'takeWhile', dart.fn(_ => true, dynamicTobool())), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-toList`, dart.dsend(it, 'toList'), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-toList`, dart.dsend(it, 'toList', {growable: false}), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-toList`, dart.dsend(it, 'toList', {growable: true}), dart.dsend(depth, '-', 1));
        testType(dart.str`${name}-toSet`, dart.dsend(it, 'toSet'), dart.dsend(depth, '-', 1));
      }
    }
    dart.fn(testType, dynamicAnddynamic__Todynamic());
    function test(name, it) {
      testEmpty(name, it);
      testType(name, it);
    }
    dart.fn(test, dynamicAnddynamicTodynamic());
    test("const", const$ || (const$ = dart.const(IterableOfint().empty())));
    test("new", IterableOfint().empty());
  };
  dart.fn(iterable_empty_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_empty_test = iterable_empty_test;
});
