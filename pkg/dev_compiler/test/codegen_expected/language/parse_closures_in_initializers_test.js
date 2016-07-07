dart_library.library('language/parse_closures_in_initializers_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parse_closures_in_initializers_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parse_closures_in_initializers_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let JSArrayOfVoidTodynamic = () => (JSArrayOfVoidTodynamic = dart.constFn(_interceptors.JSArray$(VoidTodynamic())))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  parse_closures_in_initializers_test.A = class A extends core.Object {
    static foo(f) {
      return dart.dcall(f);
    }
    parenthesized(y) {
      this.x = dart.fn(() => y, VoidTodynamic$());
    }
    stringLiteral(y) {
      this.x = dart.str`**${dart.fn(() => y, VoidTodynamic$())}--`;
    }
    listLiteral(y) {
      this.x = JSArrayOfVoidTodynamic().of([dart.fn(() => y, VoidTodynamic$())]);
    }
    mapLiteral(y) {
      this.x = dart.map({fun: dart.fn(() => y, VoidTodynamic$())});
    }
    arg(y) {
      this.x = parse_closures_in_initializers_test.A.foo(dart.fn(() => y, VoidTodynamic$()));
    }
  };
  dart.defineNamedConstructor(parse_closures_in_initializers_test.A, 'parenthesized');
  dart.defineNamedConstructor(parse_closures_in_initializers_test.A, 'stringLiteral');
  dart.defineNamedConstructor(parse_closures_in_initializers_test.A, 'listLiteral');
  dart.defineNamedConstructor(parse_closures_in_initializers_test.A, 'mapLiteral');
  dart.defineNamedConstructor(parse_closures_in_initializers_test.A, 'arg');
  dart.setSignature(parse_closures_in_initializers_test.A, {
    constructors: () => ({
      parenthesized: dart.definiteFunctionType(parse_closures_in_initializers_test.A, [dart.dynamic]),
      stringLiteral: dart.definiteFunctionType(parse_closures_in_initializers_test.A, [dart.dynamic]),
      listLiteral: dart.definiteFunctionType(parse_closures_in_initializers_test.A, [dart.dynamic]),
      mapLiteral: dart.definiteFunctionType(parse_closures_in_initializers_test.A, [dart.dynamic]),
      arg: dart.definiteFunctionType(parse_closures_in_initializers_test.A, [dart.dynamic])
    }),
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])}),
    names: ['foo']
  });
  parse_closures_in_initializers_test.main = function() {
    let a = null, f = null;
    a = new parse_closures_in_initializers_test.A.parenthesized(499);
    f = dart.dload(a, 'x');
    expect$.Expect.isTrue(core.Function.is(f));
    expect$.Expect.equals(499, dart.dcall(f));
    a = new parse_closures_in_initializers_test.A.stringLiteral(42);
    expect$.Expect.isTrue(dart.dsend(dart.dload(a, 'x'), 'startsWith', "**"));
    expect$.Expect.isTrue(dart.dsend(dart.dload(a, 'x'), 'endsWith', "--"));
    a = new parse_closures_in_initializers_test.A.listLiteral(99);
    f = dart.dindex(dart.dload(a, 'x'), 0);
    expect$.Expect.isTrue(core.Function.is(f));
    expect$.Expect.equals(99, dart.dcall(f));
    a = new parse_closures_in_initializers_test.A.mapLiteral(314);
    f = dart.dindex(dart.dload(a, 'x'), "fun");
    expect$.Expect.isTrue(core.Function.is(f));
    expect$.Expect.equals(314, dart.dcall(f));
    a = new parse_closures_in_initializers_test.A.arg(123);
    expect$.Expect.equals(123, dart.dload(a, 'x'));
  };
  dart.fn(parse_closures_in_initializers_test.main, VoidTodynamic$());
  // Exports:
  exports.parse_closures_in_initializers_test = parse_closures_in_initializers_test;
});
