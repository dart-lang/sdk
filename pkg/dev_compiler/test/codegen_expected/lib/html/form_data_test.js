dart_library.library('lib/html/form_data_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__form_data_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const form_data_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ProgressEventTovoid = () => (ProgressEventTovoid = dart.constFn(dart.functionType(dart.void, [html.ProgressEvent])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let ProgressEventTovoid$ = () => (ProgressEventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.ProgressEvent])))();
  form_data_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.FormData[dartx.supported], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('unsupported throws', dart.fn(() => {
        let expectation = dart.test(html.FormData[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          html.FormData.new();
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      let isFormData = src__matcher__core_matchers.predicate(dart.fn(x => html.FormData.is(x), dynamicTobool()), 'is a FormData');
      if (dart.test(html.FormData[dartx.supported])) {
        unittest$.test('constructorTest1', dart.fn(() => {
          let form = html.FormData.new();
          src__matcher__expect.expect(form, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(form, isFormData);
        }, VoidTodynamic()));
        unittest$.test('constructorTest2', dart.fn(() => {
          let form = html.FormData.new(html.FormElement.new());
          src__matcher__expect.expect(form, src__matcher__core_matchers.isNotNull);
          src__matcher__expect.expect(form, isFormData);
        }, VoidTodynamic()));
        unittest$.test('appendTest', dart.fn(() => {
          let form = html.FormData.new();
          form[dartx.append]('test', '1');
          form[dartx.append]('username', 'Elmo');
          form[dartx.append]('address', '1 Sesame Street');
          form[dartx.append]('password', '123456');
          src__matcher__expect.expect(form, src__matcher__core_matchers.isNotNull);
        }, VoidTodynamic()));
        unittest$.test('appendBlob', dart.fn(() => {
          let form = html.FormData.new();
          let blob = html.Blob.new(JSArrayOfString().of(['Indescribable... Indestructible! Nothing can stop it!']), 'text/plain');
          form[dartx.appendBlob]('theBlob', blob, 'theBlob.txt');
        }, VoidTodynamic()));
        unittest$.test('send', dart.fn(() => {
          let form = html.FormData.new();
          let blobString = 'Indescribable... Indestructible! Nothing can stop it!';
          let blob = html.Blob.new(JSArrayOfString().of([blobString]), 'text/plain');
          form[dartx.appendBlob]('theBlob', blob, 'theBlob.txt');
          let xhr = html.HttpRequest.new();
          xhr[dartx.open]('POST', dart.str`${html.window[dartx.location][dartx.protocol]}//${html.window[dartx.location][dartx.host]}/echo`);
          xhr[dartx.onLoad].listen(ProgressEventTovoid()._check(unittest$.expectAsync(dart.fn(e => {
            src__matcher__expect.expect(xhr[dartx.responseText], src__matcher__core_matchers.contains(blobString));
          }, dynamicTodynamic()))));
          xhr[dartx.onError].listen(dart.fn(e => {
            src__matcher__expect.fail(dart.str`${e}`);
          }, ProgressEventTovoid$()));
          xhr[dartx.send](form);
        }, VoidTodynamic()));
      }
    }, VoidTovoid()));
  };
  dart.fn(form_data_test.main, VoidTovoid());
  // Exports:
  exports.form_data_test = form_data_test;
});
