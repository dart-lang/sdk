dart_library.library('language/default_factory_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__default_factory_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const default_factory_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_factory_test_none_multi.Vehicle = class Vehicle extends core.Object {};
  default_factory_test_none_multi.Bike = class Bike extends core.Object {
    redOne() {
    }
  };
  dart.defineNamedConstructor(default_factory_test_none_multi.Bike, 'redOne');
  default_factory_test_none_multi.Bike[dart.implements] = () => [default_factory_test_none_multi.Vehicle, default_factory_test_none_multi.GoogleOne];
  dart.setSignature(default_factory_test_none_multi.Bike, {
    constructors: () => ({redOne: dart.definiteFunctionType(default_factory_test_none_multi.Bike, [])})
  });
  default_factory_test_none_multi.SpaceShip = class SpaceShip extends core.Object {
    static new() {
      return default_factory_test_none_multi.GoogleOne.new();
    }
  };
  dart.setSignature(default_factory_test_none_multi.SpaceShip, {
    constructors: () => ({new: dart.definiteFunctionType(default_factory_test_none_multi.SpaceShip, [])})
  });
  default_factory_test_none_multi.GoogleOne = class GoogleOne extends core.Object {
    internal_() {
    }
    static new() {
      return new default_factory_test_none_multi.GoogleOne.internal_();
    }
    static Vehicle() {
      return new default_factory_test_none_multi.Bike.redOne();
    }
  };
  dart.defineNamedConstructor(default_factory_test_none_multi.GoogleOne, 'internal_');
  default_factory_test_none_multi.GoogleOne[dart.implements] = () => [default_factory_test_none_multi.SpaceShip];
  dart.setSignature(default_factory_test_none_multi.GoogleOne, {
    constructors: () => ({
      internal_: dart.definiteFunctionType(default_factory_test_none_multi.GoogleOne, []),
      new: dart.definiteFunctionType(default_factory_test_none_multi.GoogleOne, []),
      Vehicle: dart.definiteFunctionType(default_factory_test_none_multi.GoogleOne, [])
    })
  });
  default_factory_test_none_multi.main = function() {
    expect$.Expect.equals(true, default_factory_test_none_multi.Bike.is(new default_factory_test_none_multi.Bike.redOne()));
    expect$.Expect.equals(true, default_factory_test_none_multi.GoogleOne.is(default_factory_test_none_multi.SpaceShip.new()));
  };
  dart.fn(default_factory_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.default_factory_test_none_multi = default_factory_test_none_multi;
});
