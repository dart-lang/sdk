dart_library.library('language/named_parameters_with_conversions_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__named_parameters_with_conversions_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const named_parameters_with_conversions_test = Object.create(null);
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic])))();
  let dynamic__Todynamic$ = () => (dynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {a: dart.dynamic, b: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  named_parameters_with_conversions_test.Validate = function(tag, a, b) {
    if (dart.equals(tag, 'ab')) {
      expect$.Expect.equals(a, 111);
      expect$.Expect.equals(b, 222);
    }
    if (dart.equals(tag, 'a')) {
      expect$.Expect.equals(a, 111);
      expect$.Expect.equals(b, 20);
    }
    if (dart.equals(tag, 'b')) {
      expect$.Expect.equals(a, 10);
      expect$.Expect.equals(b, 222);
    }
    if (dart.equals(tag, '')) {
      expect$.Expect.equals(a, 10);
      expect$.Expect.equals(b, 20);
    }
  };
  dart.fn(named_parameters_with_conversions_test.Validate, dynamicAnddynamicAnddynamicTodynamic());
  named_parameters_with_conversions_test.HasMethod = class HasMethod extends core.Object {
    new() {
      this.calls = 0;
    }
    foo(tag, a, b) {
      if (a === void 0) a = 10;
      if (b === void 0) b = 20;
      this.calls = dart.notNull(this.calls) + 1;
      named_parameters_with_conversions_test.Validate(tag, a, b);
    }
    foo2(tag, opts) {
      let a = opts && 'a' in opts ? opts.a : 10;
      let b = opts && 'b' in opts ? opts.b : 20;
      this.calls = dart.notNull(this.calls) + 1;
      named_parameters_with_conversions_test.Validate(tag, a, b);
    }
  };
  dart.setSignature(named_parameters_with_conversions_test.HasMethod, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_with_conversions_test.HasMethod, [])}),
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic]),
      foo2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {a: dart.dynamic, b: dart.dynamic})
    })
  });
  named_parameters_with_conversions_test.HasField = class HasField extends core.Object {
    new() {
      this.calls = null;
      this.foo = null;
      this.foo2 = null;
      this.calls = 0;
      this.foo = this.makeFoo(this);
      this.foo2 = this.makeFoo2(this);
    }
    makeFoo(owner) {
      return dart.fn((tag, a, b) => {
        if (a === void 0) a = 10;
        if (b === void 0) b = 20;
        dart.dput(owner, 'calls', dart.dsend(dart.dload(owner, 'calls'), '+', 1));
        named_parameters_with_conversions_test.Validate(tag, a, b);
      }, dynamic__Todynamic());
    }
    makeFoo2(owner) {
      return dart.fn((tag, opts) => {
        let a = opts && 'a' in opts ? opts.a : 10;
        let b = opts && 'b' in opts ? opts.b : 20;
        dart.dput(owner, 'calls', dart.dsend(dart.dload(owner, 'calls'), '+', 1));
        named_parameters_with_conversions_test.Validate(tag, a, b);
      }, dynamic__Todynamic$());
    }
  };
  dart.setSignature(named_parameters_with_conversions_test.HasField, {
    constructors: () => ({new: dart.definiteFunctionType(named_parameters_with_conversions_test.HasField, [])}),
    methods: () => ({
      makeFoo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      makeFoo2: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  named_parameters_with_conversions_test.NamedParametersWithConversionsTest = class NamedParametersWithConversionsTest extends core.Object {
    static checkException(thunk) {
      let threw = false;
      try {
        dart.dcall(thunk);
      } catch (e) {
        threw = true;
      }

      expect$.Expect.isTrue(threw);
    }
    static testMethodCallSyntax(a) {
      dart.dsend(a, 'foo', '');
      dart.dsend(a, 'foo', 'a', 111);
      dart.dsend(a, 'foo', 'ab', 111, 222);
      dart.dsend(a, 'foo2', 'a', {a: 111});
      dart.dsend(a, 'foo2', 'b', {b: 222});
      dart.dsend(a, 'foo2', 'ab', {a: 111, b: 222});
      dart.dsend(a, 'foo2', 'ab', {b: 222, a: 111});
      expect$.Expect.equals(7, dart.dload(a, 'calls'));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dsend(a, 'foo'), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dsend(a, 'foo', 'abc', 1, 2, 3), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dsend(a, 'foo2', 'c', {c: 1}), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dsend(a, 'foo2', 'c', {a: 111, c: 1}), VoidTodynamic()));
      expect$.Expect.equals(7, dart.dload(a, 'calls'));
    }
    static testFunctionCallSyntax(a) {
      let f = dart.dload(a, 'foo');
      let f2 = dart.dload(a, 'foo2');
      dart.dcall(f, '');
      dart.dcall(f, 'a', 111);
      dart.dcall(f, 'ab', 111, 222);
      dart.dcall(f2, 'a', {a: 111});
      dart.dcall(f2, 'b', {b: 222});
      dart.dcall(f2, 'ab', {a: 111, b: 222});
      dart.dcall(f2, 'ab', {b: 222, a: 111});
      expect$.Expect.equals(7, dart.dload(a, 'calls'));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dcall(f), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dcall(f, 'abc', 1, 2, 3), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dcall(f2, 'c', {c: 1}), VoidTodynamic()));
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.checkException(dart.fn(() => dart.dcall(f2, 'c', {a: 111, c: 1}), VoidTodynamic()));
      expect$.Expect.equals(7, dart.dload(a, 'calls'));
    }
    static testMain() {
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.testMethodCallSyntax(new named_parameters_with_conversions_test.HasMethod());
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.testFunctionCallSyntax(new named_parameters_with_conversions_test.HasField());
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.testMethodCallSyntax(new named_parameters_with_conversions_test.HasField());
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.testFunctionCallSyntax(new named_parameters_with_conversions_test.HasMethod());
    }
  };
  dart.setSignature(named_parameters_with_conversions_test.NamedParametersWithConversionsTest, {
    statics: () => ({
      checkException: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testMethodCallSyntax: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testFunctionCallSyntax: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['checkException', 'testMethodCallSyntax', 'testFunctionCallSyntax', 'testMain']
  });
  named_parameters_with_conversions_test.main = function() {
    for (let i = 0; i < 20; i++) {
      named_parameters_with_conversions_test.NamedParametersWithConversionsTest.testMain();
    }
  };
  dart.fn(named_parameters_with_conversions_test.main, VoidTodynamic());
  // Exports:
  exports.named_parameters_with_conversions_test = named_parameters_with_conversions_test;
});
