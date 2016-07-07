dart_library.library('language/named_parameters_with_dollars_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_with_dollars_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_with_dollars_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic, a$b: dart.dynamic, a$$b: dart.dynamic})))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  named_parameters_with_dollars_test.main = function() {
    named_parameters_with_dollars_test.testDollar();
    named_parameters_with_dollars_test.testPsycho();
  };
  dart.fn(named_parameters_with_dollars_test.main, VoidTodynamic());
  named_parameters_with_dollars_test.TestClass = class TestClass extends core.Object {
    method(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      let a$b = opts && 'a$b' in opts ? opts.a$b : null;
      let a$$b = opts && 'a$$b' in opts ? opts.a$$b : null;
      return [a, b, a$b, a$$b];
    }
    psycho(opts) {
      let $ = opts && '$' in opts ? opts.$ : null;
      let $$ = opts && '$$' in opts ? opts.$$ : null;
      let $$$ = opts && '$$$' in opts ? opts.$$$ : null;
      let $$$$ = opts && '$$$$' in opts ? opts.$$$$ : null;
      return [$, $$, $$$, $$$$];
    }
  };
  dart.setSignature(named_parameters_with_dollars_test.TestClass, {
    methods: () => ({
      method: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic, a$b: dart.dynamic, a$$b: dart.dynamic}),
      psycho: dart.definiteFunctionType(dart.dynamic, [], {$: dart.dynamic, $$: dart.dynamic, $$$: dart.dynamic, $$$$: dart.dynamic})
    })
  });
  named_parameters_with_dollars_test.globalMethod = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
    let a$b = opts && 'a$b' in opts ? opts.a$b : null;
    let a$$b = opts && 'a$$b' in opts ? opts.a$$b : null;
    return [a, b, a$b, a$$b];
  };
  dart.fn(named_parameters_with_dollars_test.globalMethod, __Todynamic());
  named_parameters_with_dollars_test.format = function(thing) {
    if (thing == null) return '-';
    if (core.List.is(thing)) {
      let fragments = JSArrayOfString().of(['[']);
      let sep = null;
      for (let item of thing) {
        if (sep != null) fragments[dartx.add](core.String._check(sep));
        sep = ', ';
        fragments[dartx.add](core.String._check(named_parameters_with_dollars_test.format(item)));
      }
      fragments[dartx.add](']');
      return fragments[dartx.join]();
    }
    return dart.toString(thing);
  };
  dart.fn(named_parameters_with_dollars_test.format, dynamicTodynamic());
  named_parameters_with_dollars_test.makeTestClass = function(n) {
    return JSArrayOfObject().of([new named_parameters_with_dollars_test.TestClass(), new named_parameters_with_dollars_test.Decoy(), 'string'])[dartx.get](core.int._check(dart.dsend(n, '%', 3)));
  };
  dart.fn(named_parameters_with_dollars_test.makeTestClass, dynamicTodynamic());
  named_parameters_with_dollars_test.Decoy = class Decoy extends core.Object {
    method(a$b, b, a) {
      if (a$b === void 0) a$b = null;
      if (b === void 0) b = null;
      if (a === void 0) a = null;
      dart.throw(new core.UnimplementedError());
    }
    psycho($$$, $$, $) {
      if ($$$ === void 0) $$$ = null;
      if ($$ === void 0) $$ = null;
      if ($ === void 0) $ = null;
      dart.throw(new core.UnimplementedError());
    }
  };
  dart.setSignature(named_parameters_with_dollars_test.Decoy, {
    methods: () => ({
      method: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic]),
      psycho: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic])
    })
  });
  named_parameters_with_dollars_test.testDollar = function() {
    expect$.Expect.equals('[]', named_parameters_with_dollars_test.format([]));
    expect$.Expect.equals('[-, -, -, -]', named_parameters_with_dollars_test.format(named_parameters_with_dollars_test.globalMethod()));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(named_parameters_with_dollars_test.globalMethod({a: 1, b: 2})));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(named_parameters_with_dollars_test.globalMethod({b: 2, a: 1})));
    expect$.Expect.equals('[-, -, 3, -]', named_parameters_with_dollars_test.format(named_parameters_with_dollars_test.globalMethod({a$b: 3})));
    expect$.Expect.equals('[-, -, -, 4]', named_parameters_with_dollars_test.format(named_parameters_with_dollars_test.globalMethod({a$$b: 4})));
    let t = new named_parameters_with_dollars_test.TestClass();
    expect$.Expect.equals('[-, -, -, -]', named_parameters_with_dollars_test.format(t.method()));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(t.method({a: 1, b: 2})));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(t.method({b: 2, a: 1})));
    expect$.Expect.equals('[-, -, 3, -]', named_parameters_with_dollars_test.format(t.method({a$b: 3})));
    expect$.Expect.equals('[-, -, -, 4]', named_parameters_with_dollars_test.format(t.method({a$$b: 4})));
    let obj = named_parameters_with_dollars_test.makeTestClass(0);
    expect$.Expect.equals('[-, -, -, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'method')));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'method', {a: 1, b: 2})));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'method', {b: 2, a: 1})));
    expect$.Expect.equals('[-, -, 3, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'method', {a$b: 3})));
    expect$.Expect.equals('[-, -, -, 4]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'method', {a$$b: 4})));
  };
  dart.fn(named_parameters_with_dollars_test.testDollar, VoidTodynamic());
  named_parameters_with_dollars_test.testPsycho = function() {
    let t = new named_parameters_with_dollars_test.TestClass();
    expect$.Expect.equals('[1, 2, 3, -]', named_parameters_with_dollars_test.format(t.psycho({$: 1, $$: 2, $$$: 3})));
    expect$.Expect.equals('[1, 2, 3, -]', named_parameters_with_dollars_test.format(t.psycho({$$$: 3, $$: 2, $: 1})));
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(t.psycho({$: 1, $$: 2})));
    expect$.Expect.equals('[-, -, -, 4]', named_parameters_with_dollars_test.format(t.psycho({$$$$: 4})));
    let obj = named_parameters_with_dollars_test.makeTestClass(0);
    expect$.Expect.equals('[1, 2, -, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'psycho', {$: 1, $$: 2})));
    expect$.Expect.equals('[-, -, -, 4]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'psycho', {$$$$: 4})));
    expect$.Expect.equals('[1, 2, 3, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'psycho', {$: 1, $$: 2, $$$: 3})));
    expect$.Expect.equals('[1, 2, 3, -]', named_parameters_with_dollars_test.format(dart.dsend(obj, 'psycho', {$$$: 3, $$: 2, $: 1})));
  };
  dart.fn(named_parameters_with_dollars_test.testPsycho, VoidTodynamic());
  // Exports:
  exports.named_parameters_with_dollars_test = named_parameters_with_dollars_test;
});
