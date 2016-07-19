dart_library.library('language/no_such_method_mock_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__no_such_method_mock_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const no_such_method_mock_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  no_such_method_mock_test.Cat = class Cat extends core.Object {
    eatFood(food) {
      return true;
    }
    scratch(furniture) {
      return 100;
    }
  };
  dart.setSignature(no_such_method_mock_test.Cat, {
    methods: () => ({
      eatFood: dart.definiteFunctionType(core.bool, [core.String]),
      scratch: dart.definiteFunctionType(core.int, [core.String])
    })
  });
  no_such_method_mock_test.MockCat = class MockCat extends core.Object {
    noSuchMethod(invocation) {
      return core.String.as(invocation.positionalArguments[dartx.get](0))[dartx.isNotEmpty];
    }
    eatFood(food) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', [food], {isMethod: true})));
    }
    scratch(furniture) {
      return core.int._check(this.noSuchMethod(new dart.InvocationImpl('scratch', [furniture], {isMethod: true})));
    }
  };
  no_such_method_mock_test.MockCat[dart.implements] = () => [no_such_method_mock_test.Cat];
  no_such_method_mock_test.MockCat2 = class MockCat2 extends no_such_method_mock_test.MockCat {
    eatFood(food) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', [food], {isMethod: true})));
    }
    scratch(furniture) {
      return core.int._check(this.noSuchMethod(new dart.InvocationImpl('scratch', [furniture], {isMethod: true})));
    }
  };
  let const$;
  no_such_method_mock_test.MockCat3 = class MockCat3 extends no_such_method_mock_test.MockCat2 {
    noSuchMethod(invocation) {
      return dart.test(core.String.as(invocation.positionalArguments[dartx.get](0))[dartx.isNotEmpty]) && dart.test(dart.dsend(invocation.namedArguments[dartx.get](const$ || (const$ = dart.const(core.Symbol.new('amount')))), '>', 0.5));
    }
    eatFood(food, opts) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', [food], {namedArguments: opts, isMethod: true})));
    }
    scratch(furniture, furniture2) {
      return core.int._check(this.noSuchMethod(new dart.InvocationImpl('scratch', [furniture, furniture2], {isMethod: true})));
    }
  };
  no_such_method_mock_test.MockCat3[dart.implements] = () => [no_such_method_mock_test.Cat];
  no_such_method_mock_test.MockWithGenerics = class MockWithGenerics extends core.Object {
    noSuchMethod(i) {
      return dart.dsend(i.positionalArguments[dartx.get](0), '+', 100);
    }
    doStuff(T) {
      return t => {
        return T._check(this.noSuchMethod(new dart.InvocationImpl('doStuff', [t], {isMethod: true})));
      };
    }
  };
  no_such_method_mock_test.main = function() {
    let mock = new no_such_method_mock_test.MockCat();
    expect$.Expect.isTrue(dart.dsend(mock, 'eatFood', "cat food"));
    expect$.Expect.isFalse(mock.eatFood(""));
    expect$.Expect.throws(dart.fn(() => dart.notNull(mock.scratch("couch")) + 0, VoidToint()));
    let mock2 = new no_such_method_mock_test.MockCat2();
    expect$.Expect.isTrue(mock2.eatFood("cat food"));
    let mock3 = new no_such_method_mock_test.MockCat3();
    expect$.Expect.isTrue(mock3.eatFood("cat food", {amount: 0.9}));
    expect$.Expect.isFalse(mock3.eatFood("cat food", {amount: 0.3}));
    let g = new no_such_method_mock_test.MockWithGenerics();
    expect$.Expect.equals(g.doStuff(core.int)(42), 142);
    expect$.Expect.throws(dart.fn(() => g.doStuff(dart.dynamic)('hi'), VoidTovoid()));
  };
  dart.fn(no_such_method_mock_test.main, VoidTovoid());
  // Exports:
  exports.no_such_method_mock_test = no_such_method_mock_test;
});
