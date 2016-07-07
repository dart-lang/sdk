dart_library.library('language/nullaware_opt_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__nullaware_opt_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const nullaware_opt_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfintToListOfint = () => (ListOfintToListOfint = dart.constFn(dart.definiteFunctionType(ListOfint(), [ListOfint()])))();
  nullaware_opt_test.C = class C extends core.Object {
    new(f) {
      this.f = f;
    }
    m(a) {
      return a;
    }
  };
  dart.setSignature(nullaware_opt_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(nullaware_opt_test.C, [dart.dynamic])}),
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  nullaware_opt_test.bomb = function() {
    expect$.Expect.fail('Should not be executed');
    return 100;
  };
  dart.fn(nullaware_opt_test.bomb, VoidTodynamic());
  nullaware_opt_test.getNull = function() {
    return null;
  };
  dart.fn(nullaware_opt_test.getNull, VoidTodynamic());
  nullaware_opt_test.test = function() {
    let c = null;
    let d = new nullaware_opt_test.C(5);
    expect$.Expect.equals(null, dart.nullSafe(c, _ => dart.dsend(_, 'm', nullaware_opt_test.bomb())));
    expect$.Expect.equals(null, dart.nullSafe(nullaware_opt_test.getNull(), _ => dart.dsend(_, 'anything', nullaware_opt_test.bomb())));
    expect$.Expect.equals(1, dart.nullSafe(d, _ => _.m(1)));
    expect$.Expect.equals(1, new nullaware_opt_test.C(1).f);
    expect$.Expect.equals(null, dart.nullSafe(c, _ => dart.dload(_, 'v')));
    expect$.Expect.equals(10, (c != null ? c : 10));
    expect$.Expect.equals(d, (d != null ? d : nullaware_opt_test.bomb()));
    expect$.Expect.equals(3, JSArrayOfListOfint().of([JSArrayOfint().of([3])])[dartx.expand](core.int)(dart.fn(i => i, ListOfintToListOfint()))[dartx.toList]()[dartx.get](0));
    expect$.Expect.equals(null, dart.nullSafe(null, _ => _[dartx.expand](core.int)(dart.fn(i => i, ListOfintToListOfint())), _ => _[dartx.toList]()));
    let e = null;
    let t = d;
    t == null ? d = nullaware_opt_test.C._check((() => {
      let t = e;
      return t == null ? e = new nullaware_opt_test.C(100) : t;
    })()) : t;
    expect$.Expect.equals(null, e);
    let t$ = e;
    t$ == null ? e = new nullaware_opt_test.C(100) : t$;
    expect$.Expect.equals(100, dart.nullSafe(e, _ => dart.dload(_, 'f')));
    let t$0 = dart.nullSafe(e, _ => dart.dload(_, 'f'));
    t$0 == null ? (() => {
      let l = e;
      return l == null ? null : dart.dput(l, 'f', 200);
    })() : t$0;
    expect$.Expect.equals(100, dart.nullSafe(e, _ => dart.dload(_, 'f')));
    dart.dput(e, 'f', null);
    let t$1 = dart.nullSafe(e, _ => dart.dload(_, 'f'));
    t$1 == null ? (() => {
      let l = e;
      return l == null ? null : dart.dput(l, 'f', 200);
    })() : t$1;
    expect$.Expect.equals(200, dart.nullSafe(e, _ => dart.dload(_, 'f')));
    let t$2 = dart.nullSafe(c, _ => dart.dload(_, 'f'));
    t$2 == null ? (c == null ? null : dart.dput(c, 'f', 400)) : t$2;
    expect$.Expect.equals(null, dart.nullSafe(c, _ => dart.dload(_, 'f')));
    expect$.Expect.equals(null, (() => {
      let x = dart.nullSafe(c, _ => dart.dload(_, 'f'));
      c == null ? null : dart.dput(c, 'f', dart.dsend(x, '+', 1));
      return x;
    })());
    let l = e;
    l == null ? null : dart.dput(l, 'f', dart.dsend(dart.nullSafe(e, _ => dart.dload(_, 'f')), '+', 1));
    expect$.Expect.equals(201, dart.dload(e, 'f'));
    let x = 5;
  };
  dart.fn(nullaware_opt_test.test, VoidTodynamic());
  nullaware_opt_test.test2 = function() {
    let c = null;
    dart.nullSafe(c, _ => dart.dload(_, 'v'));
    dart.nullSafe(c, _ => dart.dsend(_, 'm', nullaware_opt_test.bomb()));
  };
  dart.fn(nullaware_opt_test.test2, VoidTodynamic());
  nullaware_opt_test.main = function() {
    for (let i = 0; i < 10; i++) {
      nullaware_opt_test.test();
      nullaware_opt_test.test2();
    }
  };
  dart.fn(nullaware_opt_test.main, VoidTodynamic());
  // Exports:
  exports.nullaware_opt_test = nullaware_opt_test;
});
