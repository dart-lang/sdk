dart_library.library('lib/html/document_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__document_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const document_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  document_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let isElement = src__matcher__core_matchers.predicate(dart.fn(x => html.Element.is(x), dynamicTobool()), 'is an Element');
    let isDivElement = src__matcher__core_matchers.predicate(dart.fn(x => html.DivElement.is(x), dynamicTobool()), 'is a DivElement');
    let isAnchorElement = src__matcher__core_matchers.predicate(dart.fn(x => html.AnchorElement.is(x), dynamicTobool()), 'is an AnchorElement');
    let isUnknownElement = src__matcher__core_matchers.predicate(dart.fn(x => html.UnknownElement.is(x), dynamicTobool()), 'is UnknownElement');
    let inscrutable = null;
    unittest$.test('CreateElement', dart.fn(() => {
      src__matcher__expect.expect(html.Element.tag('span'), isElement);
      src__matcher__expect.expect(html.Element.tag('div'), isDivElement);
      src__matcher__expect.expect(html.Element.tag('a'), isAnchorElement);
      src__matcher__expect.expect(html.Element.tag('bad_name'), isUnknownElement);
    }, VoidTodynamic()));
    unittest$.group('document', dart.fn(() => {
      inscrutable = dart.fn(x => x, dynamicTodynamic());
      unittest$.test('Document.query', dart.fn(() => {
        let doc = html.DomParser.new()[dartx.parseFromString]('<ResultSet>\n           <Row>A</Row>\n           <Row>B</Row>\n           <Row>C</Row>\n         </ResultSet>', 'text/xml');
        let rs = doc[dartx.query]('ResultSet');
        src__matcher__expect.expect(rs, src__matcher__core_matchers.isNotNull);
      }, VoidTodynamic()));
      unittest$.test('CreateElement', dart.fn(() => {
        src__matcher__expect.expect(html.Element.tag('span'), isElement);
        src__matcher__expect.expect(html.Element.tag('div'), isDivElement);
        src__matcher__expect.expect(html.Element.tag('a'), isAnchorElement);
        src__matcher__expect.expect(html.Element.tag('bad_name'), isUnknownElement);
      }, VoidTodynamic()));
      unittest$.test('adoptNode', dart.fn(() => {
        let div = html.Element.html('<div><div id="foo">bar</div></div>');
        let doc = html.document[dartx.implementation][dartx.createHtmlDocument]('');
        src__matcher__expect.expect(doc[dartx.adoptNode](div), div);
        src__matcher__expect.expect(div[dartx.ownerDocument], doc);
        doc[dartx.body][dartx.nodes][dartx.add](div);
        src__matcher__expect.expect(doc[dartx.query]('#foo')[dartx.text], 'bar');
      }, VoidTodynamic()));
      unittest$.test('importNode', dart.fn(() => {
        let div = html.Element.html('<div><div id="foo">bar</div></div>');
        let doc = html.document[dartx.implementation][dartx.createHtmlDocument]('');
        let div2 = doc[dartx.importNode](div, true);
        src__matcher__expect.expect(div2, src__matcher__operator_matchers.isNot(src__matcher__core_matchers.equals(div)));
        src__matcher__expect.expect(div2[dartx.ownerDocument], doc);
        doc[dartx.body][dartx.nodes][dartx.add](div2);
        src__matcher__expect.expect(doc[dartx.query]('#foo')[dartx.text], 'bar');
      }, VoidTodynamic()));
      unittest$.test('typeTest1', dart.fn(() => {
        inscrutable = dart.dcall(inscrutable, inscrutable);
        let doc1 = html.document;
        src__matcher__expect.expect(html.HtmlDocument.is(doc1), true);
        src__matcher__expect.expect(html.HtmlDocument.is(dart.dcall(inscrutable, doc1)), true);
        let doc2 = html.document[dartx.implementation][dartx.createHtmlDocument]('');
        src__matcher__expect.expect(html.HtmlDocument.is(doc2), true);
        src__matcher__expect.expect(html.HtmlDocument.is(dart.dcall(inscrutable, doc2)), true);
      }, VoidTodynamic()));
      unittest$.test('typeTest2', dart.fn(() => {
        inscrutable = dart.dcall(inscrutable, inscrutable);
        let doc3 = html.document[dartx.implementation][dartx.createDocument](null, 'report', null);
        src__matcher__expect.expect(html.HtmlDocument.is(doc3), false);
        src__matcher__expect.expect(html.HtmlDocument.is(dart.dcall(inscrutable, doc3)), false);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(document_test.main, VoidTodynamic());
  // Exports:
  exports.document_test = document_test;
});
