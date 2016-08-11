dart_library.library('language/inline_super_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inline_super_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inline_super_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inline_super_test.Percept = class Percept extends core.Object {};
  inline_super_test.Actor = class Actor extends core.Object {
    new(percept) {
      this.percept = percept;
    }
  };
  dart.setSignature(inline_super_test.Actor, {
    constructors: () => ({new: dart.definiteFunctionType(inline_super_test.Actor, [dart.dynamic])})
  });
  inline_super_test.LivingActor = class LivingActor extends inline_super_test.Actor {
    new() {
      super.new(new inline_super_test.Percept());
    }
  };
  dart.setSignature(inline_super_test.LivingActor, {
    constructors: () => ({new: dart.definiteFunctionType(inline_super_test.LivingActor, [])})
  });
  inline_super_test.main = function() {
    expect$.Expect.isTrue(inline_super_test.Percept.is(new inline_super_test.Player().percept));
  };
  dart.fn(inline_super_test.main, VoidTodynamic());
  inline_super_test.Player = class Player extends inline_super_test.LivingActor {
    new() {
      super.new();
    }
  };
  dart.setSignature(inline_super_test.Player, {
    constructors: () => ({new: dart.definiteFunctionType(inline_super_test.Player, [])})
  });
  // Exports:
  exports.inline_super_test = inline_super_test;
});
