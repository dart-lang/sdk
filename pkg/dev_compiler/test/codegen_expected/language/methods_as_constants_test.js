dart_library.library('language/methods_as_constants_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__methods_as_constants_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const methods_as_constants_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  methods_as_constants_test.topLevelMethod = function() {
    return 't';
  };
  dart.fn(methods_as_constants_test.topLevelMethod, VoidTodynamic$());
  methods_as_constants_test.topLevelFieldForTopLevelMethod = methods_as_constants_test.topLevelMethod;
  methods_as_constants_test.A = class A extends core.Object {
    new(closure) {
      this.closure = closure;
    }
    defaultTopLevel(closure) {
      if (closure === void 0) closure = methods_as_constants_test.topLevelMethod;
      this.closure = closure;
    }
    defaultStatic(closure) {
      if (closure === void 0) closure = methods_as_constants_test.A.staticMethod;
      this.closure = closure;
    }
    defaultStatic2(closure) {
      if (closure === void 0) closure = methods_as_constants_test.A.staticMethod;
      this.closure = closure;
    }
    run() {
      return dart.dcall(this.closure);
    }
    static staticMethod() {
      return 's';
    }
  };
  dart.defineNamedConstructor(methods_as_constants_test.A, 'defaultTopLevel');
  dart.defineNamedConstructor(methods_as_constants_test.A, 'defaultStatic');
  dart.defineNamedConstructor(methods_as_constants_test.A, 'defaultStatic2');
  dart.setSignature(methods_as_constants_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(methods_as_constants_test.A, [core.Function]),
      defaultTopLevel: dart.definiteFunctionType(methods_as_constants_test.A, [], [core.Function]),
      defaultStatic: dart.definiteFunctionType(methods_as_constants_test.A, [], [core.Function]),
      defaultStatic2: dart.definiteFunctionType(methods_as_constants_test.A, [], [core.Function])
    }),
    methods: () => ({run: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({staticMethod: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['staticMethod']
  });
  methods_as_constants_test.A.staticFieldForTopLevelMethod = methods_as_constants_test.topLevelMethod;
  dart.defineLazy(methods_as_constants_test.A, {
    get staticFieldForStaticMethod() {
      return methods_as_constants_test.A.staticMethod;
    }
  });
  methods_as_constants_test.topLevelFieldForStaticMethod = methods_as_constants_test.A.staticMethod;
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  methods_as_constants_test.main = function() {
    expect$.Expect.equals('t', (const$ || (const$ = dart.const(new methods_as_constants_test.A(methods_as_constants_test.topLevelMethod)))).run());
    expect$.Expect.equals('s', (const$0 || (const$0 = dart.const(new methods_as_constants_test.A(methods_as_constants_test.A.staticMethod)))).run());
    expect$.Expect.equals('t', (const$1 || (const$1 = dart.const(new methods_as_constants_test.A.defaultTopLevel()))).run());
    expect$.Expect.equals('s', (const$2 || (const$2 = dart.const(new methods_as_constants_test.A.defaultStatic()))).run());
    expect$.Expect.equals('s', (const$3 || (const$3 = dart.const(new methods_as_constants_test.A.defaultStatic2()))).run());
    expect$.Expect.equals('t', new methods_as_constants_test.A.defaultTopLevel().run());
    expect$.Expect.equals('s', new methods_as_constants_test.A.defaultStatic().run());
    expect$.Expect.equals('s', new methods_as_constants_test.A.defaultStatic2().run());
    expect$.Expect.equals('t', methods_as_constants_test.topLevelFieldForTopLevelMethod());
    expect$.Expect.equals('s', methods_as_constants_test.topLevelFieldForStaticMethod());
    expect$.Expect.equals('t', methods_as_constants_test.A.staticFieldForTopLevelMethod());
    expect$.Expect.equals('s', methods_as_constants_test.A.staticFieldForStaticMethod());
    let map = const$4 || (const$4 = dart.const(dart.map({t: methods_as_constants_test.topLevelMethod, s: methods_as_constants_test.A.staticMethod}, core.String, VoidTodynamic())));
    expect$.Expect.equals('t', map[dartx.get]('t')());
    expect$.Expect.equals('s', map[dartx.get]('s')());
  };
  dart.fn(methods_as_constants_test.main, VoidTodynamic$());
  // Exports:
  exports.methods_as_constants_test = methods_as_constants_test;
});
