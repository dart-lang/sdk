dart_library.library('corelib/expando_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__expando_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const expando_test = Object.create(null);
  let ExpandoOfint = () => (ExpandoOfint = dart.constFn(core.Expando$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  expando_test.ExpandoTest = class ExpandoTest extends core.Object {
    static testMain() {
      expando_test.ExpandoTest.visits = new (ExpandoOfint())('visits');
      let legal = JSArrayOfObject().of([new core.Object(), core.List.new(), JSArrayOfint().of([1, 2, 3]), const$ || (const$ = dart.constList([1, 2, 3], core.int)), core.Map.new(), dart.map({x: 1, y: 2}), const$0 || (const$0 = dart.const(dart.map({x: 1, y: 2}))), new core.Expando(), new core.Expando('horse')]);
      for (let object of legal) {
        expando_test.ExpandoTest.testNamedExpando(object);
        expando_test.ExpandoTest.testUnnamedExpando(object);
      }
      for (let object of legal) {
        expect$.Expect.equals(2, expando_test.ExpandoTest.visits.get(object), dart.str`${object}`);
      }
      expando_test.ExpandoTest.testIllegal();
      expando_test.ExpandoTest.testIdentity();
    }
    static visit(object) {
      let count = expando_test.ExpandoTest.visits.get(object);
      count = count == null ? 1 : dart.notNull(count) + 1;
      expando_test.ExpandoTest.visits.set(object, count);
    }
    static testNamedExpando(object) {
      let expando = new (ExpandoOfint())('myexpando');
      expect$.Expect.equals('myexpando', expando.name);
      expect$.Expect.isTrue(expando.toString()[dartx.startsWith]('Expando:myexpando'));
      expando_test.ExpandoTest.testExpando(expando, object);
    }
    static testUnnamedExpando(object) {
      let expando = new (ExpandoOfint())();
      expect$.Expect.isNull(expando.name);
      expect$.Expect.isTrue(expando.toString()[dartx.startsWith]('Expando:'));
      expando_test.ExpandoTest.testExpando(expando, object);
    }
    static testExpando(expando, object) {
      expando_test.ExpandoTest.visit(object);
      expect$.Expect.isNull(expando.get(object));
      expando.set(object, 42);
      expect$.Expect.equals(42, expando.get(object));
      expando.set(object, null);
      expect$.Expect.isNull(expando.get(object));
      let alternative = new (ExpandoOfint())('myexpando');
      expect$.Expect.isNull(alternative.get(object));
      alternative.set(object, 87);
      expect$.Expect.isNull(expando.get(object));
      expando.set(object, 99);
      expect$.Expect.equals(99, expando.get(object));
      expect$.Expect.equals(87, alternative.get(object));
    }
    static testIllegal() {
      let expando = new (ExpandoOfint())();
      expect$.Expect.throws(dart.fn(() => expando.get(null), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "null");
      expect$.Expect.throws(dart.fn(() => expando.get('string'), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "'string'");
      expect$.Expect.throws(dart.fn(() => expando.get('string'), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "'string'");
      expect$.Expect.throws(dart.fn(() => expando.get(42), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "42");
      expect$.Expect.throws(dart.fn(() => expando.get(42.87), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "42.87");
      expect$.Expect.throws(dart.fn(() => expando.get(true), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "true");
      expect$.Expect.throws(dart.fn(() => expando.get(false), VoidToint()), dart.fn(exception => core.ArgumentError.is(exception), dynamicTobool()), "false");
    }
    static testIdentity() {
      let expando = new (ExpandoOfint())();
      let m1 = new expando_test.Mutable(1);
      let m2 = new expando_test.Mutable(7);
      let m3 = new expando_test.Mutable(13);
      expando.set(m1, 42);
      expect$.Expect.equals(42, expando.get(m1));
      m1.id = 37;
      expect$.Expect.equals(42, expando.get(m1));
      expando.set(m2, 37);
      expando.set(m3, 10);
      m3.id = 1;
      expect$.Expect.equals(42, expando.get(m1));
      expect$.Expect.equals(37, expando.get(m2));
      expect$.Expect.equals(10, expando.get(m3));
    }
  };
  dart.setSignature(expando_test.ExpandoTest, {
    statics: () => ({
      testMain: dart.definiteFunctionType(dart.dynamic, []),
      visit: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testNamedExpando: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testUnnamedExpando: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testExpando: dart.definiteFunctionType(dart.dynamic, [core.Expando$(core.int), dart.dynamic]),
      testIllegal: dart.definiteFunctionType(dart.dynamic, []),
      testIdentity: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['testMain', 'visit', 'testNamedExpando', 'testUnnamedExpando', 'testExpando', 'testIllegal', 'testIdentity']
  });
  expando_test.ExpandoTest.visits = null;
  expando_test.main = function() {
    return expando_test.ExpandoTest.testMain();
  };
  dart.fn(expando_test.main, VoidTodynamic());
  expando_test.Mutable = class Mutable extends core.Object {
    new(id) {
      this.id = id;
    }
    get hashCode() {
      return this.id;
    }
    ['=='](other) {
      return expando_test.Mutable.is(other) && other.id == this.id;
    }
  };
  dart.setSignature(expando_test.Mutable, {
    constructors: () => ({new: dart.definiteFunctionType(expando_test.Mutable, [core.int])})
  });
  // Exports:
  exports.expando_test = expando_test;
});
