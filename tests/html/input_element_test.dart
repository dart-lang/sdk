library input_element_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  test('hidden', () {
    var e = new HiddenInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'hidden');
  });

  test('search', () {
    var e = new SearchInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'search');
  });

  test('text', () {
    var e = new TextInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'text');
  });

  test('url', () {
    var e = new UrlInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'url');
  });

  test('telephone', () {
    var e = new TelephoneInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'tel');
  });

  test('email', () {
    var e = new EmailInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'email');
  });

  test('password', () {
    var e = new PasswordInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'password');
  });

  group('datetime', () {
    test('constructor', () {
      var e = new DateTimeInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'datetime');
    });
  });

  group('date', () {
    test('constructor', () {
      var e = new DateInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'date');
    });
  });

  group('month', () {
    test('constructor', () {
      var e = new MonthInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'month');
    });
  });

  group('week', () {
    test('constructor', () {
      var e = new WeekInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'week');
    });
  });

  group('time', () {
    test('constructor', () {
      var e = new TimeInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'time');
    });
  });

  group('datetime-local', () {
    test('constructor', () {
      var e = new LocalDateTimeInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'datetime-local');
    });
  });

  test('number', () {
    var e = new NumberInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'number');
  });

  group('range', () {
    test('constructor', () {
      var e = new RangeInputElement();
      expect(e is InputElement, true);
      expect(e.type, 'range');
    });
  });

  test('checkbox', () {
    var e = new CheckboxInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'checkbox');
  });

  test('radio', () {
    var e = new RadioButtonInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'radio');
  });

  test('file', () {
    var e = new FileUploadInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'file');
  });

  test('submit', () {
    var e = new SubmitButtonInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'submit');
  });

  test('image', () {
    var e = new ImageButtonInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'image');
  });

  test('reset', () {
    var e = new ResetButtonInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'reset');
  });

  test('button', () {
    var e = new ButtonInputElement();
    expect(e is InputElement, true);
    expect(e.type, 'button');
  });
}
