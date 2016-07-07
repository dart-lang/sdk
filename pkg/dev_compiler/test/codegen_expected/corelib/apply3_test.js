dart_library.library('corelib/apply3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__apply3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const apply3_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let MapOfSymbol$dynamic = () => (MapOfSymbol$dynamic = dart.constFn(core.Map$(core.Symbol, dart.dynamic)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  apply3_test.F = dart.callableClass(function F(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class F extends core.Object {
    call(p1) {
      if (p1 === void 0) p1 = null;
      return "call";
    }
    noSuchMethod(invocation) {
      return "NSM";
    }
  });
  dart.setSignature(apply3_test.F, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])})
  });
  apply3_test.G = dart.callableClass(function G(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class G extends core.Object {
    call() {
      return '42';
    }
    noSuchMethod(invocation) {
      return invocation;
    }
  });
  dart.setSignature(apply3_test.G, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])})
  });
  apply3_test.H = dart.callableClass(function H(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class H extends core.Object {
    call(required, opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      return dart.dsend(required, '+', a);
    }
  });
  dart.setSignature(apply3_test.H, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {a: dart.dynamic})})
  });
  let const$;
  let const$0;
  apply3_test.main = function() {
    expect$.Expect.equals('call', core.Function.apply(new apply3_test.F(), []));
    expect$.Expect.equals('call', core.Function.apply(new apply3_test.F(), JSArrayOfint().of([1])));
    expect$.Expect.equals('NSM', core.Function.apply(new apply3_test.F(), JSArrayOfint().of([1, 2])));
    expect$.Expect.equals('NSM', core.Function.apply(new apply3_test.F(), JSArrayOfint().of([1, 2, 3])));
    let symbol = const$ || (const$ = dart.const(core.Symbol.new('a')));
    let requiredParameters = JSArrayOfint().of([1]);
    let optionalParameters = core.Map.new();
    optionalParameters[dartx.set](symbol, 42);
    let i = core.Invocation._check(core.Function.apply(new apply3_test.G(), requiredParameters, MapOfSymbol$dynamic()._check(optionalParameters)));
    expect$.Expect.equals(const$0 || (const$0 = dart.const(core.Symbol.new('call'))), i.memberName);
    expect$.Expect.listEquals(requiredParameters, i.positionalArguments);
    expect$.Expect.mapEquals(optionalParameters, i.namedArguments);
    expect$.Expect.isTrue(i.isMethod);
    expect$.Expect.isFalse(i.isGetter);
    expect$.Expect.isFalse(i.isSetter);
    expect$.Expect.isFalse(i.isAccessor);
    requiredParameters[dartx.set](0, 42);
    optionalParameters[dartx.set](symbol, 12);
    expect$.Expect.listEquals(JSArrayOfint().of([1]), i.positionalArguments);
    expect$.Expect.mapEquals((() => {
      let _ = core.Map.new();
      _[dartx.set](symbol, 42);
      return _;
    })(), i.namedArguments);
    let mirror = mirrors.reflect(new apply3_test.G());
    let other = core.Invocation._check(mirror.delegate(i));
    expect$.Expect.equals(i.memberName, other.memberName);
    expect$.Expect.listEquals(i.positionalArguments, other.positionalArguments);
    expect$.Expect.mapEquals(i.namedArguments, other.namedArguments);
    expect$.Expect.equals(i.isMethod, other.isMethod);
    expect$.Expect.equals(i.isGetter, other.isGetter);
    expect$.Expect.equals(i.isSetter, other.isSetter);
    expect$.Expect.equals(i.isAccessor, other.isAccessor);
    expect$.Expect.equals(43, new apply3_test.H().call(1, {a: 42}));
    expect$.Expect.equals(43, core.Function.apply(new apply3_test.H(), JSArrayOfint().of([1]), (() => {
      let _ = MapOfSymbol$dynamic().new();
      _[dartx.set](symbol, 42);
      return _;
    })()));
    mirror = mirrors.reflect(new apply3_test.H());
    expect$.Expect.equals(43, mirror.delegate(i));
    expect$.Expect.equals(43, mirror.delegate(other));
  };
  dart.fn(apply3_test.main, VoidTodynamic());
  // Exports:
  exports.apply3_test = apply3_test;
});
