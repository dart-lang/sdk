dart_library.library('corelib/hashcode_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__hashcode_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const hashcode_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  hashcode_test.Override = class Override extends core.Object {
    new() {
      this.hash = null;
    }
    get superHash() {
      return super.hashCode;
    }
    get hashCode() {
      return this.hash;
    }
    foo() {
      return this.hash;
    }
    ['=='](other) {
      return hashcode_test.Override.is(other) && other.hash == this.hash;
    }
  };
  dart.setSignature(hashcode_test.Override, {
    methods: () => ({
      foo: dart.definiteFunctionType(core.int, []),
      '==': dart.definiteFunctionType(core.bool, [core.Object])
    })
  });
  hashcode_test.bar = function() {
    return 42;
  };
  dart.fn(hashcode_test.bar, VoidToint());
  let const$;
  hashcode_test.main = function() {
    let o = new core.Object();
    let hash = o.hashCode;
    expect$.Expect.equals(hash, o.hashCode);
    expect$.Expect.equals(hash, core.identityHashCode(o));
    let c = new hashcode_test.Override();
    let identityHash = c.superHash;
    hash = identityHash == 42 ? 37 : 42;
    c.hash = hash;
    expect$.Expect.equals(hash, c.hashCode);
    expect$.Expect.equals(identityHash, core.identityHashCode(c));
    let samples = JSArrayOfObject().of([0, 268435456, 1.5, -0, null, true, false, const$ || (const$ = dart.const(new core.Object()))]);
    for (let v of samples) {
      core.print(v);
      expect$.Expect.equals(dart.hashCode(v), core.identityHashCode(v));
    }
    samples = JSArrayOfObject().of(["string", "", dart.fn(x => 42, dynamicToint()), dart.bind(c, 'foo'), hashcode_test.bar]);
    for (let v of samples) {
      core.print(v);
      expect$.Expect.equals(dart.hashCode(v), dart.hashCode(v));
      expect$.Expect.equals(core.identityHashCode(v), core.identityHashCode(v));
    }
  };
  dart.fn(hashcode_test.main, VoidTodynamic());
  // Exports:
  exports.hashcode_test = hashcode_test;
});
