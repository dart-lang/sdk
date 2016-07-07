dart_library.library('corelib/set_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__set_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const set_to_string_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  set_to_string_test.main = function() {
    let s = collection.HashSet.new();
    s.add(1);
    expect$.Expect.equals("{1}", s.toString());
    s.remove(1);
    s.add(s);
    expect$.Expect.equals("{{...}}", s.toString());
    let q = new collection.ListQueue(4);
    q.add(1);
    q.add(2);
    q.add(q);
    q.add(s);
    expect$.Expect.equals("{1, 2, {...}, {{...}}}", q.toString());
    q.addLast(new set_to_string_test.ThrowOnToString());
    expect$.Expect.throws(dart.bind(q, 'toString'), dart.fn(e => dart.equals(e, "Bad!"), dynamicTobool()));
    q.removeLast();
    expect$.Expect.equals("{1, 2, {...}, {{...}}}", q.toString());
  };
  dart.fn(set_to_string_test.main, VoidTovoid());
  set_to_string_test.ThrowOnToString = class ThrowOnToString extends core.Object {
    toString() {
      dart.throw("Bad!");
    }
  };
  // Exports:
  exports.set_to_string_test = set_to_string_test;
});
