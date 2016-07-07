dart_library.library('lib/html/form_element_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__form_element_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const form_element_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  form_element_test.main = function() {
    html_config.useHtmlConfiguration();
    let isFormElement = src__matcher__core_matchers.predicate(dart.fn(x => html.FormElement.is(x), dynamicTobool()), 'is a FormElement');
    unittest$.test('constructorTest1', dart.fn(() => {
      let form = html.FormElement.new();
      src__matcher__expect.expect(form, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(form, isFormElement);
    }, VoidTodynamic()));
    unittest$.test('checkValidityTest', dart.fn(() => {
      let form = html.FormElement.new();
      form[dartx.innerHtml] = '<label>Google: <input type="search" name="q"></label> ' + '<input type="submit" value="Search...">';
      src__matcher__expect.expect(form[dartx.checkValidity](), src__matcher__core_matchers.isTrue);
      form[dartx.innerHtml] = '<input type="email" value="notemail" blaber="test"' + ' required>';
      src__matcher__expect.expect(form[dartx.checkValidity](), src__matcher__core_matchers.isFalse);
    }, VoidTodynamic()));
    let form = html.FormElement.new();
    unittest$.test('acceptCharsetTest', dart.fn(() => {
      let charset = 'abc';
      form[dartx.acceptCharset] = charset;
      src__matcher__expect.expect(form[dartx.acceptCharset], charset);
    }, VoidTodynamic()));
    unittest$.test('actionTest', dart.fn(() => {
      let action = 'http://dartlang.org/';
      form[dartx.action] = action;
      src__matcher__expect.expect(form[dartx.action], action);
    }, VoidTodynamic()));
    unittest$.test('autocompleteTest', dart.fn(() => {
      let auto = 'on';
      form[dartx.autocomplete] = auto;
      src__matcher__expect.expect(form[dartx.autocomplete], auto);
    }, VoidTodynamic()));
    unittest$.test('encodingAndEnctypeTest', dart.fn(() => {
      src__matcher__expect.expect(form[dartx.enctype], form[dartx.encoding]);
    }, VoidTodynamic()));
    unittest$.test('lengthTest', dart.fn(() => {
      src__matcher__expect.expect(form[dartx.length], 0);
      form[dartx.innerHtml] = '<label>Google: <input type="search" name="q"></label> ' + '<input type="submit" value="Search...">';
      src__matcher__expect.expect(form[dartx.length], 2);
    }, VoidTodynamic()));
    unittest$.test('methodTest', dart.fn(() => {
      let method = 'post';
      form[dartx.method] = method;
      src__matcher__expect.expect(form[dartx.method], method);
    }, VoidTodynamic()));
    unittest$.test('nameTest', dart.fn(() => {
      let name = 'aname';
      form[dartx.name] = name;
      src__matcher__expect.expect(form[dartx.name], name);
    }, VoidTodynamic()));
    unittest$.test('noValidateTest', dart.fn(() => {
      form[dartx.noValidate] = true;
      src__matcher__expect.expect(form[dartx.noValidate], true);
    }, VoidTodynamic()));
    unittest$.test('targetTest', dart.fn(() => {
      let target = 'target';
      form[dartx.target] = target;
      src__matcher__expect.expect(form[dartx.target], target);
    }, VoidTodynamic()));
  };
  dart.fn(form_element_test.main, VoidTovoid());
  // Exports:
  exports.form_element_test = form_element_test;
});
