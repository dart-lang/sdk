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
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  no_such_method_mock_test.Cat = class Cat extends core.Object {
    eatFood(food) {
      return true;
    }
    scratch(furniture) {
      return 'purr';
    }
  };
  dart.setSignature(no_such_method_mock_test.Cat, {
    methods: () => ({
      eatFood: dart.definiteFunctionType(core.bool, [core.String]),
      scratch: dart.definiteFunctionType(core.String, [core.String])
    })
  });
  no_such_method_mock_test.MockCat = class MockCat extends core.Object {
    noSuchMethod(invocation) {
      return core.String.as(invocation.positionalArguments[dartx.get](0))[dartx.isNotEmpty];
    }
    eatFood(...args) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', args, {isMethod: true})));
    }
    scratch(...args) {
      return core.String._check(this.noSuchMethod(new dart.InvocationImpl('scratch', args, {isMethod: true})));
    }
  };
  no_such_method_mock_test.MockCat[dart.implements] = () => [no_such_method_mock_test.Cat];
  no_such_method_mock_test.MockCat2 = class MockCat2 extends no_such_method_mock_test.MockCat {
    eatFood(...args) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', args, {isMethod: true})));
    }
    scratch(...args) {
      return core.String._check(this.noSuchMethod(new dart.InvocationImpl('scratch', args, {isMethod: true})));
    }
  };
  let const$;
  let const$0;
  no_such_method_mock_test.MockCat3 = class MockCat3 extends no_such_method_mock_test.MockCat2 {
    noSuchMethod(invocation) {
      if (dart.equals(invocation.memberName, const$ || (const$ = dart.const(core.Symbol.new('scratch'))))) {
        return invocation.positionalArguments[dartx.join](',');
      }
      return dart.test(core.String.as(invocation.positionalArguments[dartx.get](0))[dartx.isNotEmpty]) && dart.test(dart.dsend(invocation.namedArguments[dartx.get](const$0 || (const$0 = dart.const(core.Symbol.new('amount')))), '>', 0.5));
    }
    eatFood(...args) {
      return core.bool._check(this.noSuchMethod(new dart.InvocationImpl('eatFood', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
    }
    scratch(...args) {
      return core.String._check(this.noSuchMethod(new dart.InvocationImpl('scratch', args, {isMethod: true})));
    }
  };
  no_such_method_mock_test.MockCat3[dart.implements] = () => [no_such_method_mock_test.Cat];
  no_such_method_mock_test.MockWithGenerics = class MockWithGenerics extends core.Object {
    noSuchMethod(i) {
      return dart.dsend(i.positionalArguments[dartx.get](0), '+', 100);
    }
    doStuff(T) {
      return (...args) => {
        return T._check(this.noSuchMethod(new dart.InvocationImpl('doStuff', args, {isMethod: true})));
      };
    }
  };
  no_such_method_mock_test.MockWithGetterSetter = class MockWithGetterSetter extends core.Object {
    new() {
      this.invocation = null;
    }
    noSuchMethod(i) {
      this.invocation = i;
    }
    get getter() {
      return this.noSuchMethod(new dart.InvocationImpl('getter', [], {isGetter: true}));
    }
    set setter(args) {
      return dart.void._check(this.noSuchMethod(new dart.InvocationImpl('setter', [args], {isSetter: true})));
    }
  };
  no_such_method_mock_test.main = function() {
    let mock = new no_such_method_mock_test.MockCat();
    expect$.Expect.isTrue(dart.dsend(mock, 'eatFood', "cat food"));
    expect$.Expect.isFalse(mock.eatFood(""));
    expect$.Expect.throws(dart.fn(() => dart.notNull(mock.scratch("couch")) + '', VoidToString()));
    let mock2 = new no_such_method_mock_test.MockCat2();
    expect$.Expect.isTrue(mock2.eatFood("cat food"));
    let mock3 = new no_such_method_mock_test.MockCat3();
    expect$.Expect.isTrue(mock3.eatFood("cat food", {amount: 0.9}));
    expect$.Expect.isFalse(mock3.eatFood("cat food", {amount: 0.3}));
    expect$.Expect.equals(mock3.scratch("chair"), "chair");
    expect$.Expect.equals(mock3.scratch("chair", "couch"), "chair,couch");
    expect$.Expect.equals(mock3.scratch("chair", null), "chair,null");
    expect$.Expect.equals(mock3.scratch("chair", ""), "chair,");
    let g = new no_such_method_mock_test.MockWithGenerics();
    expect$.Expect.equals(g.doStuff(core.int)(42), 142);
    expect$.Expect.throws(dart.fn(() => g.doStuff(dart.dynamic)('hi'), VoidTovoid()));
    let s = new no_such_method_mock_test.MockWithGetterSetter();
    s.getter;
    expect$.Expect.equals(s.invocation.positionalArguments[dartx.length], 0);
    expect$.Expect.equals(s.invocation.isGetter, true);
    expect$.Expect.equals(s.invocation.isSetter, false);
    expect$.Expect.equals(s.invocation.isMethod, false);
    s.setter = 42;
    expect$.Expect.equals(s.invocation.positionalArguments[dartx.single], 42);
    expect$.Expect.equals(s.invocation.isGetter, false);
    expect$.Expect.equals(s.invocation.isSetter, true);
    expect$.Expect.equals(s.invocation.isMethod, false);
  };
  dart.fn(no_such_method_mock_test.main, VoidTovoid());
  // Exports:
  exports.no_such_method_mock_test = no_such_method_mock_test;
});
