dart_library.library('language/inst_field_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inst_field_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inst_field_initializer_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inst_field_initializer_test.Cheese = class Cheese extends core.Object {
    new() {
      this.name = "";
      this.smell = inst_field_initializer_test.Cheese.mild;
      expect$.Expect.equals("", this.name);
      expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, this.smell);
    }
    initInBlock(s) {
      this.name = "";
      this.smell = inst_field_initializer_test.Cheese.mild;
      expect$.Expect.equals("", this.name);
      expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, this.smell);
      this.name = s;
    }
    initFieldParam(name, smell) {
      this.name = name;
      this.smell = smell;
    }
    hideAndSeek(mild) {
      this.name = core.String._check(mild);
      this.smell = inst_field_initializer_test.Cheese.mild;
      expect$.Expect.equals(mild, this.name);
      expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, this.smell);
    }
  };
  dart.defineNamedConstructor(inst_field_initializer_test.Cheese, 'initInBlock');
  dart.defineNamedConstructor(inst_field_initializer_test.Cheese, 'initFieldParam');
  dart.defineNamedConstructor(inst_field_initializer_test.Cheese, 'hideAndSeek');
  dart.setSignature(inst_field_initializer_test.Cheese, {
    constructors: () => ({
      new: dart.definiteFunctionType(inst_field_initializer_test.Cheese, []),
      initInBlock: dart.definiteFunctionType(inst_field_initializer_test.Cheese, [core.String]),
      initFieldParam: dart.definiteFunctionType(inst_field_initializer_test.Cheese, [core.String, core.int]),
      hideAndSeek: dart.definiteFunctionType(inst_field_initializer_test.Cheese, [dart.dynamic])
    })
  });
  inst_field_initializer_test.Cheese.mild = 1;
  inst_field_initializer_test.Cheese.stinky = 2;
  inst_field_initializer_test.HasNoExplicitConstructor = class HasNoExplicitConstructor extends core.Object {
    new() {
      this.s = "Tilsiter";
    }
  };
  inst_field_initializer_test.main = function() {
    let generic = new inst_field_initializer_test.Cheese();
    expect$.Expect.equals("", generic.name);
    expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, generic.smell);
    let gruyere = new inst_field_initializer_test.Cheese.initInBlock("Gruyere");
    expect$.Expect.equals("Gruyere", gruyere.name);
    expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, gruyere.smell);
    let munster = new inst_field_initializer_test.Cheese.initFieldParam("Munster", inst_field_initializer_test.Cheese.stinky);
    expect$.Expect.equals("Munster", munster.name);
    expect$.Expect.equals(inst_field_initializer_test.Cheese.stinky, munster.smell);
    let brie = new inst_field_initializer_test.Cheese.hideAndSeek("Brie");
    expect$.Expect.equals("Brie", brie.name);
    expect$.Expect.equals(inst_field_initializer_test.Cheese.mild, brie.smell);
    let t = new inst_field_initializer_test.HasNoExplicitConstructor();
    expect$.Expect.equals("Tilsiter", t.s);
  };
  dart.fn(inst_field_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.inst_field_initializer_test = inst_field_initializer_test;
});
