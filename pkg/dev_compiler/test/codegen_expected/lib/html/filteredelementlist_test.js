dart_library.library('lib/html/filteredelementlist_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__filteredelementlist_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const html_common = dart_sdk.html_common;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const src__matcher__error_matchers = unittest.src__matcher__error_matchers;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const filteredelementlist_test = Object.create(null);
  let JSArrayOfDivElement = () => (JSArrayOfDivElement = dart.constFn(_interceptors.JSArray$(html.DivElement)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToElement = () => (VoidToElement = dart.constFn(dart.definiteFunctionType(html.Element, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  filteredelementlist_test.main = function() {
    let t1 = html.Text.new('T1'), t2 = html.Text.new('T2'), t3 = html.Text.new('T3'), t4 = html.Text.new('T4');
    let d1 = html.DivElement.new(), d2 = html.DivElement.new(), d3 = html.DivElement.new();
    function createTestDiv() {
      let testDiv = html.DivElement.new();
      testDiv[dartx.append](t1);
      testDiv[dartx.append](d1);
      testDiv[dartx.append](t2);
      testDiv[dartx.append](d2);
      testDiv[dartx.append](t3);
      testDiv[dartx.append](d3);
      testDiv[dartx.append](t4);
      return testDiv;
    }
    dart.fn(createTestDiv, VoidTodynamic());
    html_config.useHtmlConfiguration();
    unittest$.test('FilteredElementList.insert test', dart.fn(() => {
      let i = html.DivElement.new();
      let nodeList = createTestDiv();
      let elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insert(0, i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 0), t1);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 1), i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 2), d1);
      nodeList = createTestDiv();
      elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insert(1, i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 2), t2);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 3), i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 4), d2);
      nodeList = createTestDiv();
      elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insert(2, i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 4), t3);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 5), i);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 6), d3);
    }, VoidTodynamic()));
    unittest$.test('FilteredElementList.insertAll test', dart.fn(() => {
      let i1 = html.DivElement.new(), i2 = html.DivElement.new();
      let it = JSArrayOfDivElement().of([i1, i2]);
      let nodeList = createTestDiv();
      let elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insertAll(0, it);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 0), t1);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 1), i1);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 2), i2);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 3), d1);
      nodeList = createTestDiv();
      elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insertAll(1, it);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 2), t2);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 3), i1);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 4), i2);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 5), d2);
      nodeList = createTestDiv();
      elementList = new html_common.FilteredElementList(html.Node._check(nodeList));
      elementList.insertAll(2, it);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 4), t3);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 5), i1);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 6), i2);
      src__matcher__expect.expect(dart.dindex(dart.dload(nodeList, 'childNodes'), 7), d3);
    }, VoidTodynamic()));
    unittest$.test('FilteredElementList.insertAndRemove', dart.fn(() => {
      let emptyDiv = html.DivElement.new();
      let elementList = new html_common.FilteredElementList(emptyDiv);
      src__matcher__expect.expect(dart.fn(() => elementList.get(0), VoidToElement()), src__matcher__throws_matcher.throwsA(src__matcher__error_matchers.isRangeError));
      src__matcher__expect.expect(dart.fn(() => elementList.insert(2, html.BRElement.new()), VoidTovoid()), src__matcher__throws_matcher.throwsA(src__matcher__error_matchers.isRangeError));
      let br = html.BRElement.new();
      elementList.insert(0, br);
      src__matcher__expect.expect(elementList.removeLast(), br);
      elementList.add(br);
      src__matcher__expect.expect(elementList.remove(br), src__matcher__core_matchers.isTrue);
      let br2 = html.BRElement.new();
      elementList.add(br);
      src__matcher__expect.expect(elementList.remove(br2), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(elementList.get(0), br);
      src__matcher__expect.expect(dart.fn(() => elementList.get(1), VoidToElement()), src__matcher__throws_matcher.throwsA(src__matcher__error_matchers.isRangeError));
    }, VoidTodynamic()));
  };
  dart.fn(filteredelementlist_test.main, VoidTodynamic());
  // Exports:
  exports.filteredelementlist_test = filteredelementlist_test;
});
