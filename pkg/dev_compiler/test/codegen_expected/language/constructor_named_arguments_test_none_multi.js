dart_library.library('language/constructor_named_arguments_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_named_arguments_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_named_arguments_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  constructor_named_arguments_test_none_multi.message = null;
  constructor_named_arguments_test_none_multi.foo = function() {
    constructor_named_arguments_test_none_multi.message = dart.notNull(constructor_named_arguments_test_none_multi.message) + 'foo';
    return 1;
  };
  dart.fn(constructor_named_arguments_test_none_multi.foo, VoidTodynamic());
  constructor_named_arguments_test_none_multi.bar = function() {
    constructor_named_arguments_test_none_multi.message = dart.notNull(constructor_named_arguments_test_none_multi.message) + 'bar';
    return 2;
  };
  dart.fn(constructor_named_arguments_test_none_multi.bar, VoidTodynamic());
  constructor_named_arguments_test_none_multi.X = class X extends core.Object {
    new(opts) {
      let a = opts && 'a' in opts ? opts.a : 'defa';
      let b = opts && 'b' in opts ? opts.b : 'defb';
      this.i = a;
      this.j = b;
    }
    foo() {
      X.prototype.new.call(this, {b: 1, a: 2});
    }
    bar() {
      X.prototype.new.call(this, {a: 2});
    }
    baz() {
      X.prototype.new.call(this, {a: 1, b: 2});
    }
    qux() {
      X.prototype.new.call(this, {b: 2});
    }
    hest() {
      X.prototype.new.call(this);
    }
    fisk() {
      X.prototype.new.call(this, {b: constructor_named_arguments_test_none_multi.bar(), a: constructor_named_arguments_test_none_multi.foo()});
    }
    naebdyr() {
      X.prototype.new.call(this, {a: constructor_named_arguments_test_none_multi.foo(), b: constructor_named_arguments_test_none_multi.bar()});
    }
  };
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'foo');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'bar');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'baz');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'qux');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'hest');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'fisk');
  dart.defineNamedConstructor(constructor_named_arguments_test_none_multi.X, 'naebdyr');
  dart.setSignature(constructor_named_arguments_test_none_multi.X, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, [], {a: dart.dynamic, b: dart.dynamic}),
      foo: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      bar: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      baz: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      qux: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      hest: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      fisk: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, []),
      naebdyr: dart.definiteFunctionType(constructor_named_arguments_test_none_multi.X, [])
    })
  });
  constructor_named_arguments_test_none_multi.test = function(x, a, b) {
    expect$.Expect.equals(dart.dload(x, 'i'), a);
    expect$.Expect.equals(dart.dload(x, 'j'), b);
  };
  dart.fn(constructor_named_arguments_test_none_multi.test, dynamicAnddynamicAnddynamicTodynamic());
  constructor_named_arguments_test_none_multi.main = function() {
    constructor_named_arguments_test_none_multi.test(new constructor_named_arguments_test_none_multi.X.foo(), 2, 1);
    constructor_named_arguments_test_none_multi.test(new constructor_named_arguments_test_none_multi.X.bar(), 2, 'defb');
    constructor_named_arguments_test_none_multi.test(new constructor_named_arguments_test_none_multi.X.baz(), 1, 2);
    constructor_named_arguments_test_none_multi.test(new constructor_named_arguments_test_none_multi.X.qux(), 'defa', 2);
    constructor_named_arguments_test_none_multi.test(new constructor_named_arguments_test_none_multi.X.hest(), 'defa', 'defb');
    constructor_named_arguments_test_none_multi.message = '';
    new constructor_named_arguments_test_none_multi.X.fisk();
    expect$.Expect.equals('barfoo', constructor_named_arguments_test_none_multi.message);
    constructor_named_arguments_test_none_multi.message = '';
    new constructor_named_arguments_test_none_multi.X.naebdyr();
    expect$.Expect.equals('foobar', constructor_named_arguments_test_none_multi.message);
  };
  dart.fn(constructor_named_arguments_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_named_arguments_test_none_multi = constructor_named_arguments_test_none_multi;
});
