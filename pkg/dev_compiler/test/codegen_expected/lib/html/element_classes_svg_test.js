dart_library.library('lib/html/element_classes_svg_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__element_classes_svg_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const svg = dart_sdk.svg;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__expect = unittest.src__matcher__expect;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__iterable_matchers = unittest.src__matcher__iterable_matchers;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const element_classes_svg_test = Object.create(null);
  let ElementListOfElement = () => (ElementListOfElement = dart.constFn(html.ElementList$(html.Element)))();
  let LinkedHashSetOfString = () => (LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))();
  let SetOfString = () => (SetOfString = dart.constFn(core.Set$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToElement = () => (VoidToElement = dart.constFn(dart.definiteFunctionType(html.Element, [])))();
  let VoidToElementListOfElement = () => (VoidToElementListOfElement = dart.constFn(dart.definiteFunctionType(ElementListOfElement(), [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let ElementToSetOfString = () => (ElementToSetOfString = dart.constFn(dart.definiteFunctionType(SetOfString(), [html.Element])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  element_classes_svg_test.makeElementsContainer = function() {
    let e = html.Element.html('<ul class="yes foo">' + '<li class="yes quux qux">' + '</ul>');
    let svgContent = "<svg version=\"1.1\">\n  <circle class=\"yes qux\"></circle>\n  <path class=\"yes classy\"></path>\n</svg>";
    let svgElement = svg.SvgElement.svg(svgContent);
    e[dartx.append](svgElement);
    return e;
  };
  dart.fn(element_classes_svg_test.makeElementsContainer, VoidToElement());
  element_classes_svg_test.elementsContainer = null;
  element_classes_svg_test.elementsSetup = function() {
    element_classes_svg_test.elementsContainer = element_classes_svg_test.makeElementsContainer();
    html.document[dartx.documentElement][dartx.children][dartx.add](element_classes_svg_test.elementsContainer);
    let elements = html.document[dartx.querySelectorAll](html.Element)('.yes');
    src__matcher__expect.expect(elements.length, 4);
    return elements;
  };
  dart.fn(element_classes_svg_test.elementsSetup, VoidToElementListOfElement());
  element_classes_svg_test.elementsTearDown = function() {
    if (element_classes_svg_test.elementsContainer != null) {
      html.document[dartx.documentElement][dartx.children][dartx.remove](element_classes_svg_test.elementsContainer);
      element_classes_svg_test.elementsContainer = null;
    }
  };
  dart.fn(element_classes_svg_test.elementsTearDown, VoidTovoid());
  element_classes_svg_test.view = function(e) {
    if (core.Set.is(e)) return dart.str`${(() => {
      let _ = e.toList();
      _[dartx.sort]();
      return _;
    })()}`;
    if (html.Element.is(e)) return element_classes_svg_test.view(e[dartx.classes]);
    if (core.Iterable.is(e)) return dart.str`${e[dartx.map](core.String)(element_classes_svg_test.view)[dartx.toList]()}`;
    dart.throw(new core.ArgumentError(dart.str`Cannot make canonical view string for: ${e}}`));
  };
  dart.fn(element_classes_svg_test.view, dynamicToString());
  element_classes_svg_test.main = function() {
    html_config.useHtmlConfiguration();
    function extractClasses(el) {
      let match = core.RegExp.new('class="([^"]+)"').firstMatch(el[dartx.outerHtml]);
      return LinkedHashSetOfString().from(match.get(1)[dartx.split](' '));
    }
    dart.fn(extractClasses, ElementToSetOfString());
    unittest$.tearDown(element_classes_svg_test.elementsTearDown);
    unittest$.test('list_view', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, quux, qux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, yes], [quux, qux, yes], [qux, yes], [classy, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listClasses=', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes = JSArrayOfString().of(['foo', 'qux']);
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[foo, qux]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, qux], [foo, qux], [foo, qux], [foo, qux]]');
      let elements2 = html.document[dartx.querySelectorAll](html.Element)('.qux');
      src__matcher__expect.expect(element_classes_svg_test.view(elements2.classes), '[foo, qux]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements2), '[[foo, qux], [foo, qux], [foo, qux], [foo, qux]]');
      for (let e of elements2) {
        src__matcher__expect.expect(e[dartx.classes], src__matcher__iterable_matchers.orderedEquals(JSArrayOfString().of(['foo', 'qux'])));
        src__matcher__expect.expect(extractClasses(e), src__matcher__iterable_matchers.orderedEquals(JSArrayOfString().of(['foo', 'qux'])));
      }
      elements.classes = JSArrayOfString().of([]);
      src__matcher__expect.expect(element_classes_svg_test.view(elements2.classes), '[]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements2), '[[], [], [], []]');
    }, VoidTodynamic()));
    unittest$.test('listMap', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      src__matcher__expect.expect(elements.classes.map(core.String)(dart.fn(c => c[dartx.toUpperCase](), StringToString()))[dartx.toList](), src__matcher__iterable_matchers.unorderedEquals(JSArrayOfString().of(['YES', 'FOO', 'QUX', 'QUUX', 'CLASSY'])));
    }, VoidTodynamic()));
    unittest$.test('listContains', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      src__matcher__expect.expect(elements.classes.contains('classy'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(elements.classes.contains('troll'), src__matcher__core_matchers.isFalse);
    }, VoidTodynamic()));
    unittest$.test('listAdd', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      let added = elements.classes.add('lassie');
      src__matcher__expect.expect(added, src__matcher__core_matchers.isNull);
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, lassie, quux, qux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, lassie, yes], [lassie, quux, qux, yes], ' + '[lassie, qux, yes], [classy, lassie, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listRemove', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      src__matcher__expect.expect(elements.classes.remove('lassi'), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, quux, qux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, yes], [quux, qux, yes], [qux, yes], [classy, yes]]');
      src__matcher__expect.expect(elements.classes.remove('qux'), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, quux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, yes], [quux, yes], [yes], [classy, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listToggle', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.toggle('qux');
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, quux, qux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, qux, yes], [quux, yes], [yes], [classy, qux, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listAddAll', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.addAll(JSArrayOfString().of(['qux', 'lassi', 'sassy']));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, lassi, quux, qux, sassy, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, lassi, qux, sassy, yes], [lassi, quux, qux, sassy, yes], ' + '[lassi, qux, sassy, yes], [classy, lassi, qux, sassy, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listRemoveAll', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.removeAll(JSArrayOfObject().of(['qux', 'classy', 'mumble']));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[foo, quux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, yes], [quux, yes], [yes], [yes]]');
      elements.classes.removeAll(JSArrayOfObject().of(['foo', 'yes']));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[quux]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[], [quux], [], []]');
    }, VoidTodynamic()));
    unittest$.test('listToggleAll', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.toggleAll(JSArrayOfString().of(['qux', 'mornin']));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, mornin, quux, qux, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, mornin, qux, yes], [mornin, quux, yes], ' + '[mornin, yes], [classy, mornin, qux, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listRetainAll', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.retainAll(JSArrayOfObject().of(['bar', 'baz', 'classy', 'qux']));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, qux]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[], [qux], [qux], [classy]]');
    }, VoidTodynamic()));
    unittest$.test('listRemoveWhere', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.removeWhere(dart.fn(s => s[dartx.startsWith]('q'), StringTobool()));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[classy, foo, yes]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[foo, yes], [yes], [yes], [classy, yes]]');
    }, VoidTodynamic()));
    unittest$.test('listRetainWhere', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      elements.classes.retainWhere(dart.fn(s => s[dartx.startsWith]('q'), StringTobool()));
      src__matcher__expect.expect(element_classes_svg_test.view(elements.classes), '[quux, qux]');
      src__matcher__expect.expect(element_classes_svg_test.view(elements), '[[], [quux, qux], [qux], []]');
    }, VoidTodynamic()));
    unittest$.test('listContainsAll', dart.fn(() => {
      let elements = element_classes_svg_test.elementsSetup();
      src__matcher__expect.expect(elements.classes.containsAll(JSArrayOfObject().of(['qux', 'mornin'])), src__matcher__core_matchers.isFalse);
      src__matcher__expect.expect(elements.classes.containsAll(JSArrayOfObject().of(['qux', 'classy'])), src__matcher__core_matchers.isTrue);
    }, VoidTodynamic()));
  };
  dart.fn(element_classes_svg_test.main, VoidTodynamic());
  // Exports:
  exports.element_classes_svg_test = element_classes_svg_test;
});
