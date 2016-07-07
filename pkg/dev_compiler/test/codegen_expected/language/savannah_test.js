dart_library.library('language/savannah_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__savannah_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const savannah_test = Object.create(null);
  let MapOfBigGame$String = () => (MapOfBigGame$String = dart.constFn(core.Map$(savannah_test.BigGame, core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  savannah_test.BigGame = class BigGame extends core.Object {};
  savannah_test.Giraffe = class Giraffe extends core.Object {
    new(name) {
      this.name = name;
      this.identityHash_ = savannah_test.Giraffe.nextId();
    }
    get hashCode() {
      return this.identityHash_;
    }
    static nextId() {
      if (savannah_test.Giraffe.nextId_ == null) {
        savannah_test.Giraffe.nextId_ = 17;
      }
      let x = savannah_test.Giraffe.nextId_;
      savannah_test.Giraffe.nextId_ = dart.notNull(x) + 1;
      return x;
    }
  };
  savannah_test.Giraffe[dart.implements] = () => [savannah_test.BigGame];
  dart.setSignature(savannah_test.Giraffe, {
    constructors: () => ({new: dart.definiteFunctionType(savannah_test.Giraffe, [core.String])}),
    statics: () => ({nextId: dart.definiteFunctionType(core.int, [])}),
    names: ['nextId']
  });
  savannah_test.Giraffe.nextId_ = null;
  savannah_test.Zebra = class Zebra extends core.Object {
    new(name) {
      this.name = name;
    }
  };
  savannah_test.Zebra[dart.implements] = () => [savannah_test.BigGame];
  dart.setSignature(savannah_test.Zebra, {
    constructors: () => ({new: dart.definiteFunctionType(savannah_test.Zebra, [core.String])})
  });
  savannah_test.SavannahTest = class SavannahTest extends core.Object {
    static testMain() {
      let savannah = MapOfBigGame$String().new();
      let giraffe1 = new savannah_test.Giraffe("Tony");
      let giraffe2 = new savannah_test.Giraffe("Rose");
      savannah[dartx.set](giraffe1, giraffe1.name);
      savannah[dartx.set](giraffe2, giraffe2.name);
      core.print(dart.str`giraffe1 hash: ${giraffe1.hashCode}`);
      core.print(dart.str`giraffe2 hash: ${giraffe2.hashCode}`);
      let count = savannah[dartx.length];
      core.print(dart.str`getCount is ${count}`);
      expect$.Expect.equals(2, count);
      core.print(dart.str`giraffe1: ${savannah[dartx.get](giraffe1)}`);
      core.print(dart.str`giraffe2: ${savannah[dartx.get](giraffe2)}`);
      expect$.Expect.equals("Tony", savannah[dartx.get](giraffe1));
      expect$.Expect.equals("Rose", savannah[dartx.get](giraffe2));
      let zebra1 = new savannah_test.Zebra("Paolo");
      let zebra2 = new savannah_test.Zebra("Zeeta");
      savannah[dartx.set](zebra1, zebra1.name);
      savannah[dartx.set](zebra2, zebra2.name);
      core.print(dart.str`zebra1 hash: ${zebra1.hashCode}`);
      core.print(dart.str`zebra2 hash: ${zebra2.hashCode}`);
      count = savannah[dartx.length];
      core.print(dart.str`getCount is ${count}`);
      expect$.Expect.equals(4, count);
      core.print(dart.str`zebra1: ${savannah[dartx.get](zebra1)}`);
      core.print(dart.str`zebra2: ${savannah[dartx.get](zebra2)}`);
      expect$.Expect.equals("Paolo", savannah[dartx.get](zebra1));
      expect$.Expect.equals("Zeeta", savannah[dartx.get](zebra2));
    }
  };
  dart.setSignature(savannah_test.SavannahTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  savannah_test.main = function() {
    savannah_test.SavannahTest.testMain();
  };
  dart.fn(savannah_test.main, VoidTodynamic());
  // Exports:
  exports.savannah_test = savannah_test;
});
