dart_library.library('lib/html/input_element_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__input_element_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__expect = unittest.src__matcher__expect;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const input_element_test = Object.create(null);
  let InputElementAndString__Tovoid = () => (InputElementAndString__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.InputElement, core.String], [core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  input_element_test.check = function(element, type, supported) {
    if (supported === void 0) supported = true;
    src__matcher__expect.expect(html.InputElement.is(element), true);
    if (dart.test(supported)) {
      src__matcher__expect.expect(element[dartx.type], type);
    } else {
      src__matcher__expect.expect(element[dartx.type], 'text');
    }
  };
  dart.fn(input_element_test.check, InputElementAndString__Tovoid());
  input_element_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported_search', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.SearchInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_url', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.UrlInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_tel', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.TelephoneInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_email', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.EmailInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_date', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.DateInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_month', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.MonthInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_week', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.WeekInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_time', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.TimeInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_datetime-local', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.LocalDateTimeInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_number', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.NumberInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supported_range', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.RangeInputElement[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructors', dart.fn(() => {
      unittest$.test('hidden', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.HiddenInputElement.new()), 'hidden');
      }, VoidTodynamic()));
      unittest$.test('search', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.SearchInputElement.new()), 'search', html.SearchInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('text', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.TextInputElement.new()), 'text');
      }, VoidTodynamic()));
      unittest$.test('url', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.UrlInputElement.new()), 'url', html.UrlInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('telephone', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.TelephoneInputElement.new()), 'tel', html.TelephoneInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('email', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.EmailInputElement.new()), 'email', html.EmailInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('password', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.PasswordInputElement.new()), 'password');
      }, VoidTodynamic()));
      unittest$.test('date', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.DateInputElement.new()), 'date', html.DateInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('month', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.MonthInputElement.new()), 'month', html.MonthInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('week', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.WeekInputElement.new()), 'week', html.WeekInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('time', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.TimeInputElement.new()), 'time', html.TimeInputElement[dartx.supported]);
        if (dart.test(html.TimeInputElement[dartx.supported])) {
          let element = html.TimeInputElement.new();
          let now = new core.DateTime.now();
          element[dartx.valueAsDate] = now;
          src__matcher__expect.expect(core.DateTime.is(element[dartx.valueAsDate]), src__matcher__core_matchers.isTrue);
        }
      }, VoidTodynamic()));
      unittest$.test('datetime-local', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.LocalDateTimeInputElement.new()), 'datetime-local', html.LocalDateTimeInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('number', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.NumberInputElement.new()), 'number', html.NumberInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('range', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.RangeInputElement.new()), 'range', html.RangeInputElement[dartx.supported]);
      }, VoidTodynamic()));
      unittest$.test('checkbox', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.CheckboxInputElement.new()), 'checkbox');
      }, VoidTodynamic()));
      unittest$.test('radio', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.RadioButtonInputElement.new()), 'radio');
      }, VoidTodynamic()));
      unittest$.test('file', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.FileUploadInputElement.new()), 'file');
      }, VoidTodynamic()));
      unittest$.test('submit', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.SubmitButtonInputElement.new()), 'submit');
      }, VoidTodynamic()));
      unittest$.test('image', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.ImageButtonInputElement.new()), 'image');
      }, VoidTodynamic()));
      unittest$.test('reset', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.ResetButtonInputElement.new()), 'reset');
      }, VoidTodynamic()));
      unittest$.test('button', dart.fn(() => {
        input_element_test.check(html.InputElement._check(html.ButtonInputElement.new()), 'button');
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('attributes', dart.fn(() => {
      unittest$.test('valueSetNull', dart.fn(() => {
        let e = html.TextInputElement.new();
        e[dartx.value] = null;
        src__matcher__expect.expect(e[dartx.value], '');
      }, VoidTodynamic()));
      unittest$.test('valueSetNullProxy', dart.fn(() => {
        let e = html.TextInputElement.new();
        e[dartx.value] = core.String._check(input_element_test._undefined);
        src__matcher__expect.expect(e[dartx.value], '');
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(input_element_test.main, VoidTodynamic());
  dart.defineLazy(input_element_test, {
    get _undefined() {
      return dart.fn(() => core.List.new(5)[dartx.get](0), VoidTodynamic())();
    },
    set _undefined(_) {}
  });
  // Exports:
  exports.input_element_test = input_element_test;
});
