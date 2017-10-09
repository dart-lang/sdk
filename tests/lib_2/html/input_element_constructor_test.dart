import 'dart:html';

import 'package:expect/minitest.dart';

void check(InputElement element, String type, [bool supported = true]) {
  expect(element is InputElement, true);
  if (supported) {
    expect(element.type, type);
  } else {
    expect(element.type, 'text');
  }
}

main() {
  test('hidden', () {
    check(new HiddenInputElement(), 'hidden');
  });

  test('search', () {
    check(new SearchInputElement(), 'search', SearchInputElement.supported);
  });

  test('text', () {
    check(new TextInputElement(), 'text');
  });

  test('url', () {
    check(new UrlInputElement(), 'url', UrlInputElement.supported);
  });

  test('telephone', () {
    check(
        new TelephoneInputElement(), 'tel', TelephoneInputElement.supported);
  });

  test('email', () {
    check(new EmailInputElement(), 'email', EmailInputElement.supported);
  });

  test('password', () {
    check(new PasswordInputElement(), 'password');
  });

  test('date', () {
    check(new DateInputElement(), 'date', DateInputElement.supported);
  });

  test('month', () {
    check(new MonthInputElement(), 'month', MonthInputElement.supported);
  });

  test('week', () {
    check(new WeekInputElement(), 'week', WeekInputElement.supported);
  });

  test('time', () {
    check(new TimeInputElement(), 'time', TimeInputElement.supported);
    if (TimeInputElement.supported) {
      var element = new TimeInputElement();
      var now = new DateTime.now();
      element.valueAsDate = now;
      expect(element.valueAsDate is DateTime, isTrue);

      // Bug 8813, setting it is just going to the epoch.
      //expect(element.valueAsDate, now);
    }
  });

  test('datetime-local', () {
    check(new LocalDateTimeInputElement(), 'datetime-local',
        LocalDateTimeInputElement.supported);
  });

  test('number', () {
    check(new NumberInputElement(), 'number', NumberInputElement.supported);
  });

  test('range', () {
    check(new RangeInputElement(), 'range', RangeInputElement.supported);
  });

  test('checkbox', () {
    check(new CheckboxInputElement(), 'checkbox');
  });

  test('radio', () {
    check(new RadioButtonInputElement(), 'radio');
  });

  test('file', () {
    check(new FileUploadInputElement(), 'file');
  });

  test('submit', () {
    check(new SubmitButtonInputElement(), 'submit');
  });

  test('image', () {
    check(new ImageButtonInputElement(), 'image');
  });

  test('reset', () {
    check(new ResetButtonInputElement(), 'reset');
  });

  test('button', () {
    check(new ButtonInputElement(), 'button');
  });
}

