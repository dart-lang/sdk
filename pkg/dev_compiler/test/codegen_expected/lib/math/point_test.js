dart_library.library('lib/math/point_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__point_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const point_test = Object.create(null);
  let PointOfint = () => (PointOfint = dart.constFn(math.Point$(core.int)))();
  let PointOfdouble = () => (PointOfdouble = dart.constFn(math.Point$(core.double)))();
  let PointOfnum = () => (PointOfnum = dart.constFn(math.Point$(core.num)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  point_test.main = function() {
    unittest$.test('constructor', dart.fn(() => {
      let point = new (PointOfint())(0, 0);
      src__matcher__expect.expect(point.x, 0);
      src__matcher__expect.expect(point.y, 0);
      src__matcher__expect.expect(dart.str`${point}`, 'Point(0, 0)');
    }, VoidTodynamic()));
    unittest$.test('constructor X', dart.fn(() => {
      let point = new (PointOfint())(10, 0);
      src__matcher__expect.expect(point.x, 10);
      src__matcher__expect.expect(point.y, 0);
      src__matcher__expect.expect(dart.str`${point}`, 'Point(10, 0)');
    }, VoidTodynamic()));
    unittest$.test('constructor X Y', dart.fn(() => {
      let point = new (PointOfint())(10, 20);
      src__matcher__expect.expect(point.x, 10);
      src__matcher__expect.expect(point.y, 20);
      src__matcher__expect.expect(dart.str`${point}`, 'Point(10, 20)');
    }, VoidTodynamic()));
    unittest$.test('constructor X Y double', dart.fn(() => {
      let point = new (PointOfdouble())(10.5, 20.897);
      src__matcher__expect.expect(point.x, 10.5);
      src__matcher__expect.expect(point.y, 20.897);
      src__matcher__expect.expect(dart.str`${point}`, 'Point(10.5, 20.897)');
    }, VoidTodynamic()));
    unittest$.test('constructor X Y NaN', dart.fn(() => {
      let point = new (PointOfnum())(core.double.NAN, 1000);
      src__matcher__expect.expect(point.x, src__matcher__core_matchers.isNaN);
      src__matcher__expect.expect(point.y, 1000);
      src__matcher__expect.expect(dart.str`${point}`, 'Point(NaN, 1000)');
    }, VoidTodynamic()));
    unittest$.test('squaredDistanceTo', dart.fn(() => {
      let a = new (PointOfint())(7, 11);
      let b = new (PointOfint())(3, -1);
      src__matcher__expect.expect(a.squaredDistanceTo(b), 160);
      src__matcher__expect.expect(b.squaredDistanceTo(a), 160);
    }, VoidTodynamic()));
    unittest$.test('distanceTo', dart.fn(() => {
      let a = new (PointOfint())(-2, -3);
      let b = new (PointOfint())(2, 0);
      src__matcher__expect.expect(a.distanceTo(b), 5);
      src__matcher__expect.expect(b.distanceTo(a), 5);
    }, VoidTodynamic()));
    unittest$.test('subtract', dart.fn(() => {
      let a = new (PointOfint())(5, 10);
      let b = new (PointOfint())(2, 50);
      src__matcher__expect.expect(a['-'](b), new (PointOfint())(3, -40));
    }, VoidTodynamic()));
    unittest$.test('add', dart.fn(() => {
      let a = new (PointOfint())(5, 10);
      let b = new (PointOfint())(2, 50);
      src__matcher__expect.expect(a['+'](b), new (PointOfint())(7, 60));
    }, VoidTodynamic()));
    unittest$.test('hashCode', dart.fn(() => {
      let a = new (PointOfint())(0, 1);
      let b = new (PointOfint())(0, 1);
      src__matcher__expect.expect(a.hashCode, b.hashCode);
      let c = new (PointOfint())(1, 0);
      src__matcher__expect.expect(a.hashCode == c.hashCode, src__matcher__core_matchers.isFalse);
    }, VoidTodynamic()));
    unittest$.test('magnitute', dart.fn(() => {
      let a = new (PointOfint())(5, 10);
      let b = new (PointOfint())(0, 0);
      src__matcher__expect.expect(a.magnitude, a.distanceTo(b));
      src__matcher__expect.expect(b.magnitude, 0);
      let c = new (PointOfint())(-5, -10);
      src__matcher__expect.expect(c.magnitude, a.distanceTo(b));
    }, VoidTodynamic()));
  };
  dart.fn(point_test.main, VoidTodynamic());
  // Exports:
  exports.point_test = point_test;
});
