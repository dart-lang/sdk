dart_library.library('lib/html/typed_arrays_simd_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_simd_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__numeric_matchers = unittest.src__matcher__numeric_matchers;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const typed_arrays_simd_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_simd_test._FLOATING_POINT_ERROR = 1e-10;
  typed_arrays_simd_test.floatEquals = function(value) {
    return src__matcher__numeric_matchers.closeTo(core.num._check(value), typed_arrays_simd_test._FLOATING_POINT_ERROR);
  };
  dart.fn(typed_arrays_simd_test.floatEquals, dynamicTodynamic());
  typed_arrays_simd_test.MyFloat32x4 = class MyFloat32x4 extends core.Object {
    new() {
      this.x = 0.0;
      this.y = 0.0;
      this.z = 0.0;
      this.w = 0.0;
    }
  };
  typed_arrays_simd_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('test Float32x4', dart.fn(() => {
      if (dart.test(html.Platform.supportsSimd)) {
        let val = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
        src__matcher__expect.expect(val.x, typed_arrays_simd_test.floatEquals(1.0));
        src__matcher__expect.expect(val.y, typed_arrays_simd_test.floatEquals(2.0));
        src__matcher__expect.expect(val.z, typed_arrays_simd_test.floatEquals(3.0));
        src__matcher__expect.expect(val.w, typed_arrays_simd_test.floatEquals(4.0));
        let val2 = val['+'](val);
        src__matcher__expect.expect(val2.x, typed_arrays_simd_test.floatEquals(2.0));
        src__matcher__expect.expect(val2.y, typed_arrays_simd_test.floatEquals(4.0));
        src__matcher__expect.expect(val2.z, typed_arrays_simd_test.floatEquals(6.0));
        src__matcher__expect.expect(val2.w, typed_arrays_simd_test.floatEquals(8.0));
      }
    }, VoidTodynamic()));
    unittest$.test('test Float32x4List', dart.fn(() => {
      let counter = null;
      let list = typed_data.Float32List.new(12);
      for (let i = 0; i < dart.notNull(list[dartx.length]); ++i) {
        list[dartx.set](i, i * 1.0);
      }
      if (dart.test(html.Platform.supportsSimd)) {
        counter = typed_data.Float32x4.zero();
        let simdlist = typed_data.Float32x4List.view(list[dartx.buffer]);
        for (let i = 0; i < dart.notNull(simdlist.length); ++i) {
          counter = dart.dsend(counter, '+', simdlist.get(i));
        }
      } else {
        counter = new typed_arrays_simd_test.MyFloat32x4();
        for (let i = 0; i < dart.notNull(list[dartx.length]); i = i + 4) {
          dart.dput(counter, 'x', dart.dsend(dart.dload(counter, 'x'), '+', list[dartx.get](i)));
          dart.dput(counter, 'y', dart.dsend(dart.dload(counter, 'y'), '+', list[dartx.get](i + 1)));
          dart.dput(counter, 'z', dart.dsend(dart.dload(counter, 'z'), '+', list[dartx.get](i + 2)));
          dart.dput(counter, 'w', dart.dsend(dart.dload(counter, 'w'), '+', list[dartx.get](i + 3)));
        }
      }
      src__matcher__expect.expect(dart.dload(counter, 'x'), typed_arrays_simd_test.floatEquals(12.0));
      src__matcher__expect.expect(dart.dload(counter, 'y'), typed_arrays_simd_test.floatEquals(15.0));
      src__matcher__expect.expect(dart.dload(counter, 'z'), typed_arrays_simd_test.floatEquals(18.0));
      src__matcher__expect.expect(dart.dload(counter, 'w'), typed_arrays_simd_test.floatEquals(21.0));
    }, VoidTodynamic()));
    unittest$.test('test Int32x4', dart.fn(() => {
      if (dart.test(html.Platform.supportsSimd)) {
        let val = typed_data.Int32x4.new(1, 2, 3, 4);
        src__matcher__expect.expect(val.x, src__matcher__core_matchers.equals(1));
        src__matcher__expect.expect(val.y, src__matcher__core_matchers.equals(2));
        src__matcher__expect.expect(val.z, src__matcher__core_matchers.equals(3));
        src__matcher__expect.expect(val.w, src__matcher__core_matchers.equals(4));
        let val2 = val['^'](val);
        src__matcher__expect.expect(val2.x, src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(val2.y, src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(val2.z, src__matcher__core_matchers.equals(0));
        src__matcher__expect.expect(val2.w, src__matcher__core_matchers.equals(0));
      }
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_simd_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_simd_test = typed_arrays_simd_test;
});
