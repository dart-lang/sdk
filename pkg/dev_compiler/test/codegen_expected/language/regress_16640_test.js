dart_library.library('language/regress_16640_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_16640_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_16640_test = Object.create(null);
  let ConceptEntity = () => (ConceptEntity = dart.constFn(regress_16640_test.ConceptEntity$()))();
  let ConceptEntityOfSegment = () => (ConceptEntityOfSegment = dart.constFn(regress_16640_test.ConceptEntity$(regress_16640_test.Segment)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_16640_test.ConceptEntity$ = dart.generic(E => {
    class ConceptEntity extends core.Object {}
    dart.addTypeTests(ConceptEntity);
    return ConceptEntity;
  });
  regress_16640_test.ConceptEntity = ConceptEntity();
  regress_16640_test.SegmentGen = class SegmentGen extends regress_16640_test.ConceptEntity$(regress_16640_test.Segment) {};
  dart.addSimpleTypeTests(regress_16640_test.SegmentGen);
  regress_16640_test.Segment = class Segment extends regress_16640_test.SegmentGen {};
  regress_16640_test.main = function() {
    new (ConceptEntityOfSegment())();
  };
  dart.fn(regress_16640_test.main, VoidTodynamic());
  // Exports:
  exports.regress_16640_test = regress_16640_test;
});
