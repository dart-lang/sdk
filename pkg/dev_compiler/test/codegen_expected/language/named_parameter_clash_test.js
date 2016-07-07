dart_library.library('language/named_parameter_clash_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameter_clash_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameter_clash_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameter_clash_test.Foo = class Foo extends core.Object {
    m(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      let c = opts && 'c' in opts ? opts.c : null;
      try {
      } catch (e) {
      }

      return dart.str`Foo ${a} ${b} ${c}`;
    }
  };
  dart.setSignature(named_parameter_clash_test.Foo, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic, c: dart.dynamic})})
  });
  named_parameter_clash_test.Bar = class Bar extends core.Object {
    m(z, opts) {
      let a$b = opts && 'a$b' in opts ? opts.a$b : null;
      let c = opts && 'c' in opts ? opts.c : null;
      try {
      } catch (e) {
      }

      let ab = a$b;
      return dart.str`Bar ${z} ${ab} ${c}`;
    }
  };
  dart.setSignature(named_parameter_clash_test.Bar, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {a$b: dart.dynamic, c: dart.dynamic})})
  });
  named_parameter_clash_test.inscrutable = function(xs, i) {
    return dart.equals(i, 0) ? dart.dindex(xs, 0) : named_parameter_clash_test.inscrutable(dart.dsend(xs, 'sublist', 1), dart.dsend(i, '-', 1));
  };
  dart.fn(named_parameter_clash_test.inscrutable, dynamicAnddynamicTodynamic());
  named_parameter_clash_test.main = function() {
    let list = JSArrayOfObject().of([new named_parameter_clash_test.Foo(), new named_parameter_clash_test.Bar()]);
    let foo = named_parameter_clash_test.inscrutable(list, 0);
    let bar = named_parameter_clash_test.inscrutable(list, 1);
    expect$.Expect.equals('Foo a b c', dart.dsend(foo, 'm', {a: 'a', b: 'b', c: 'c'}));
    expect$.Expect.equals('Bar z a$b c', dart.dsend(bar, 'm', 'z', {a$b: 'a$b', c: 'c'}));
    expect$.Expect.throws(dart.fn(() => dart.dsend(foo, 'm', 'z', {a$b: 'a$b', c: 'c'}), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(bar, 'm', {a: 'a', b: 'b', c: 'c'}), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(named_parameter_clash_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameter_clash_test = named_parameter_clash_test;
});
