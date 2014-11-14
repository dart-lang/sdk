library input_element_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

void check(InputElement element, String type, [bool supported = true]) {
  expect(element is InputElement, true);
  if (supported) {
    expect(element.type, type);
  } else {
    expect(element.type, 'text');
  }
}

main() {
  useHtmlIndividualConfiguration();

  group('supported_search', () {
    test('supported', () {
      expect(SearchInputElement.supported, true);
    });
  });

  group('supported_url', () {
    test('supported', () {
      expect(UrlInputElement.supported, true);
    });
  });

  group('supported_tel', () {
    test('supported', () {
      expect(TelephoneInputElement.supported, true);
    });
  });

  group('supported_email', () {
    test('supported', () {
      expect(EmailInputElement.supported, true);
    });
  });

  group('supported_date', () {
    test('supported', () {
      expect(DateInputElement.supported, true);
    });
  });

  group('supported_month', () {
    test('supported', () {
      expect(MonthInputElement.supported, true);
    });
  });

  group('supported_week', () {
    test('supported', () {
      expect(WeekInputElement.supported, true);
    });
  });

  group('supported_time', () {
    test('supported', () {
      expect(TimeInputElement.supported, true);
    });
  });

  group('supported_datetime-local', () {
    test('supported', () {
      expect(LocalDateTimeInputElement.supported, true);
    });
  });

  group('supported_number', () {
    test('supported', () {
      expect(NumberInputElement.supported, true);
    });
  });

  group('supported_range', () {
    test('supported', () {
      expect(RangeInputElement.supported, true);
    });
  });

  group('constructors', () {
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
      check(new TelephoneInputElement(), 'tel',
          TelephoneInputElement.supported);
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
  });

  group('attributes', () {
    test('valueSetNull', () {
      final e = new TextInputElement();
      e.value = null;
      expect(e.value, '');
    });
    test('valueSetNullProxy', () {
      final e = new TextInputElement();
      var list = new List(5);
      e.value = list[0];
      expect(e.value, '');
    });
  });
}
