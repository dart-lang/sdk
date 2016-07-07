dart_library.library('lib/html/typed_arrays_1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_1_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const typed_arrays_1_test = Object.create(null);
  let ListOfnum = () => (ListOfnum = dart.constFn(core.List$(core.num)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  typed_arrays_1_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let isnumList = src__matcher__core_matchers.predicate(dart.fn(x => ListOfnum().is(x), dynamicTobool()), 'is a List<num>');
    let isStringList = src__matcher__core_matchers.predicate(dart.fn(x => ListOfString().is(x), dynamicTobool()), 'is a List<String>');
    let expectation = dart.test(html.Platform.supportsTypedData) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Platform.supportsTypedData, true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('arrays', dart.fn(() => {
      unittest$.test('createByLengthTest', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let a = typed_data.Float32List.new(10);
          src__matcher__expect.expect(a[dartx.length], 10);
          src__matcher__expect.expect(a[dartx.lengthInBytes], 40);
          src__matcher__expect.expect(a[dartx.get](4), 0);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('aliasTest', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let a1 = typed_data.Uint8List.fromList(JSArrayOfint().of([0, 0, 1, 69]));
          let a2 = typed_data.Float32List.view(a1[dartx.buffer]);
          src__matcher__expect.expect(a1[dartx.lengthInBytes], a2[dartx.lengthInBytes]);
          src__matcher__expect.expect(a2[dartx.length], 1);
          src__matcher__expect.expect(a2[dartx.get](0), 2048 + 16);
          a1[dartx.set](2, 0);
          src__matcher__expect.expect(a2[dartx.get](0), 2048);
          let i = 3;
          a1[dartx.set](i, dart.notNull(a1[dartx.get](i)) - 1);
          let i$ = 2;
          a1[dartx.set](i$, dart.notNull(a1[dartx.get](i$)) + 128);
          src__matcher__expect.expect(a2[dartx.get](0), 1024);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      let supportsTypeTest = !ListOfint().is(ListOfString().new());
      if (supportsTypeTest) {
        unittest$.test('typeTests', dart.fn(() => {
          src__matcher__expect.expect(dart.fn(() => {
            let a = typed_data.Float32List.new(10);
            src__matcher__expect.expect(a, src__matcher__core_matchers.isList);
            src__matcher__expect.expect(a, isnumList);
            src__matcher__expect.expect(a, src__matcher__operator_matchers.isNot(isStringList));
          }, VoidTodynamic()), expectation);
        }, VoidTodynamic()));
      }
    }, VoidTovoid()));
  };
  dart.fn(typed_arrays_1_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_1_test = typed_arrays_1_test;
});
