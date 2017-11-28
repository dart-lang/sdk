/// Debugger custom formatter tests.
/// If the tests fail, paste the expected output into the [expectedGolden]
/// string literal in this file and audit the diff to ensure changes are
/// expected.
///
/// Currently only DDC supports debugging objects with custom formatters
/// but it is reasonable to add support to Dart2JS in the future.
@JS()
library debugger_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

import 'package:expect/minitest.dart';

import 'dart:_debugger' as _debugger;

class TestClass {
  String name = 'test class';
  int date;
  static List<int> foo = [1, 2, 3, 4];
  static String greeting = 'Hello world';
  static Object bar = new Object();

  static exampleStaticMethod(x) => x * 2;

  TestClass(this.date);

  String nameAndDate() => '$name on day $date';

  int last(List<int> list) => list.last;

  void addOne(String name) {
    name = '${name}1';
  }

  get someInt => 42;
  get someString => "Hello world";
  get someObject => this;

  Object returnObject() => bar;
}

class TestGenericClass<X, Y> {
  TestGenericClass(this.x);
  X x;
}

@JS('Object.getOwnPropertyNames')
external List getOwnPropertyNames(obj);

@JS('devtoolsFormatters')
external List get _devtoolsFormatters;
List get devtoolsFormatters => _devtoolsFormatters;

@JS('JSON.stringify')
external stringify(value, [Function replacer, int space]);

// TODO(jacobr): this is only valid if the legacy library loader is used.
// We need a solution that works with all library loaders.
@JS('dart_library.import')
external importDartLibrary(String path);

@JS('ExampleJSClass')
class ExampleJSClass<T> {
  external factory ExampleJSClass(T x);
  external T get x;
}

// Replacer normalizes file names that could vary depending on the test runner.
// styles.
replacer(String key, value) {
  // The values for keys with name 'object' may be arbitrary Dart nested
  // Objects so are not safe to stringify.
  if (key == 'object') return '<OBJECT>';
  if (value is String) {
    if (value.contains('dart_sdk.js')) return '<DART_SDK>';
    if (new RegExp(r'[.](js|dart|html)').hasMatch(value)) return '<FILE>';
  }
  return value;
}

String format(value) {
  // Avoid double-escaping strings.
  if (value is String) return value;
  return stringify(value, replacer, 4);
}

class FormattedObject {
  FormattedObject(this.object, this.config);

  Object object;
  Object config;
}

/// Extract all object tags from a json ml expression to enable
/// calling the custom formatter on the extracted object tag.
List<FormattedObject> extractNestedFormattedObjects(json) {
  var ret = <FormattedObject>[];
  if (json is String || json is bool || json is num) return ret;
  if (json is List) {
    for (var e in json) {
      ret.addAll(extractNestedFormattedObjects(e));
    }
    return ret;
  }

  for (var name in getOwnPropertyNames(json)) {
    if (name == 'object') {
      // Found a nested formatted object.
      ret.add(new FormattedObject(js_util.getProperty(json, 'object'),
          js_util.getProperty(json, 'config')));
      return ret;
    }
    ret.addAll(extractNestedFormattedObjects(js_util.getProperty(json, name)));
  }
  return ret;
}

main() async {
  if (devtoolsFormatters == null) {
    print("Warning: no devtools custom formatters specified. Skipping tests.");
    return;
  }

  // Cache blocker is a workaround for:
  // https://code.google.com/p/dart/issues/detail?id=11834
  var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
  var goldenUrl = '/root_dart/tests/lib_2/html/debugger_test_golden.txt'
      '?cacheBlock=$cacheBlocker';

  String golden;
  try {
    golden = (await HttpRequest.getString(goldenUrl)).trim();
  } catch (e) {
    print("Warning: couldn't load golden file from $goldenUrl");
  }

  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
window.ExampleJSClass = function ExampleJSClass(x) {
  this.x = x;
};
""");

  var _devtoolsFormatter = devtoolsFormatters.first;

  var actual = new StringBuffer();

  // Accumulate the entire expected custom formatted data as a single
  // massive string buffer so it is simple to update expectations when
  // modifying the formatting code.
  // Otherwise a small formatting change would result in tweaking lots
  // of expectations.
  // The verify golden match test cases does the final comparison of golden
  // to expected output.
  addGolden(String name, value) {
    actual.write('Test: $name\n'
        'Value:\n'
        '${format(value)}\n'
        '-----------------------------------\n');
  }

  addFormatterGoldens(String name, object, [config]) {
    addGolden(
        '$name formatting header', _devtoolsFormatter.header(object, config));
    addGolden('$name formatting body', _devtoolsFormatter.body(object, config));
  }

  // Include goldens for the nested [[class]] definition field.
  addNestedFormatterGoldens(String name, obj) {
    addGolden('$name instance header', _devtoolsFormatter.header(obj, null));
    var body = _devtoolsFormatter.body(obj, null);
    addGolden('$name instance body', body);

    var nestedObjects = extractNestedFormattedObjects(body);
    var clazz = nestedObjects.last;
    // By convention assume last nested object is the [[class]] definition
    // describing the object's static members and inheritance hierarchy
    addFormatterGoldens('$name definition', clazz.object, clazz.config);
  }

  // Include goldens for the nested [[class]] definition field.
  addAllNestedFormatterGoldens(String name, obj) {
    addGolden('$name header', _devtoolsFormatter.header(obj, null));
    var body = _devtoolsFormatter.body(obj, null);
    addGolden('$name body', body);

    var nestedObjects = extractNestedFormattedObjects(body);
    var i = 0;
    for (var nested in nestedObjects) {
      addFormatterGoldens('$name child $i', nested.object, nested.config);
      i++;
    }
  }

  group('Iterable formatting', () {
    var list = ['foo', 'bar', 'baz'];
    var iterable = list.map((x) => x * 5);
    addFormatterGoldens('List<String>', list);

    var listOfObjects = <Object>[42, 'bar', true];

    addNestedFormatterGoldens('List<Object>', listOfObjects);

    var largeList = <int>[];
    for (var i = 0; i < 200; ++i) {
      largeList.add(i * 10);
    }
    addNestedFormatterGoldens('List<int> large', largeList);

    addNestedFormatterGoldens('Iterable', iterable);

    var s = new Set()..add("foo")..add(42)..add(true);
    addNestedFormatterGoldens('Set', s);
  });

  group('Map formatting', () {
    Map<String, int> foo = new Map();
    foo = {'1': 2, 'x': 4, '5': 6};

    addFormatterGoldens('Map<String, int>', foo);
    test('hasBody', () {
      expect(_devtoolsFormatter.hasBody(foo, null), isTrue);
    });

    Map<dynamic, dynamic> dynamicMap = new Map();
    dynamicMap = {1: 2, 'x': 4, true: "truthy"};

    addNestedFormatterGoldens('Map<dynamic, dynamic>', dynamicMap);
  });

  group('Function formatting', () {
    adder(int a, int b) => a + b;

    addFormatterGoldens('Function', adder);

    test('hasBody', () {
      expect(_devtoolsFormatter.hasBody(adder, null), isTrue);
    });

    addEventListener(String name, bool callback(Event e)) => null;

    addFormatterGoldens('Function with functon arguments', addEventListener);

    // Closure
    addGolden('dart:html method', window.addEventListener);

    // Get a reference to the JS constructor for a Dart class.
    // This tracks a regression bug where overly verbose and confusing output
    // was shown for this case.
    var testClass = new TestClass(17);
    var dartConstructor = js_util.getProperty(
        js_util.getProperty(testClass, '__proto__'), 'constructor');
    addFormatterGoldens('Raw reference to dart constructor', dartConstructor);
  });

  group('Object formatting', () {
    var object = new Object();
    addFormatterGoldens('Object', object);
    test('hasBody', () {
      expect(_devtoolsFormatter.hasBody(object, null), isTrue);
    });
  });

  group('Type formatting', () {
    addFormatterGoldens('Type TestClass', TestClass);
    addFormatterGoldens('Type HttpRequest', HttpRequest);
  });

  group('JS interop object formatting', () {
    var object = js_util.newObject();
    js_util.setProperty(object, 'foo', 'bar');
    // Make sure we don't apply the Dart custom formatter to JS interop objects.
    expect(_devtoolsFormatter.header(object, null), isNull);
  });

  group('Module formatting', () {
    var moduleNames = _debugger.getModuleNames();
    var testModuleName = "tests_lib_2_html_debugger_test/debugger_test";
    expect(moduleNames.contains(testModuleName), isTrue);

    addAllNestedFormatterGoldens(
        'Test library Module', _debugger.getModuleLibraries(testModuleName));
  });

  group('StackTrace formatting', () {
    StackTrace stack;
    try {
      throw new Error();
    } catch (exception, stackTrace) {
      stack = stackTrace;
    }
    addFormatterGoldens('StackTrace', stack);
    test('hasBody', () {
      expect(_devtoolsFormatter.hasBody(stack, null), isTrue);
    });
  });

  group('Class formatting', () {
    addNestedFormatterGoldens('TestClass', new TestClass(17));
    addNestedFormatterGoldens('MouseEvent', new MouseEvent("click"));
    // This is a good class to test as it has statics and a deep inheritance hierarchy
    addNestedFormatterGoldens('HttpRequest', new HttpRequest());
  });

  group('Generics formatting', () {
    addNestedFormatterGoldens(
        'TestGenericClass', new TestGenericClass<int, List>(42));
    addNestedFormatterGoldens(
        'TestGenericClassJSInterop',
        new TestGenericClass<ExampleJSClass<String>, int>(
            new ExampleJSClass("Hello")));
  });

  test('verify golden match', () {
    // Warning: all other test groups must have run for this test to be meaningful
    var actualStr = actual.toString().trim();

    if (actualStr != golden) {
      var helpMessage =
          'Debugger output does not match the golden data found in:\n'
          'tests/lib_strong/html/debugger_test_golden.txt\n'
          'The new golden data is copied to the clipboard when you click on '
          'this window.\n'
          'Please update the golden file with the following output and review '
          'the diff using your favorite diff tool to make sure the custom '
          'formatting output has not regressed.';
      print(helpMessage);
      print(actualStr);
      // Copy text to clipboard on page click. We can't copy to the clipboard
      // without a click due to Chrome security.
      var body = document.body;
      TextAreaElement textField = new Element.tag('textarea');
      textField.maxLength = 100000000;
      textField.text = actualStr;
      textField.style
        ..width = '800px'
        ..height = '400px';
      document.body.append(new Element.tag('h3')
        ..innerHtml = helpMessage.replaceAll('\n', '<br>'));
      document.body.append(textField);
      document.body.onClick.listen((_) {
        textField.select();
        var result = document.execCommand('copy');
        if (result) {
          print("Copy to clipboard successful");
        } else {
          print("Copy to clipboard failed");
        }
      });
    }
    expect(actualStr == golden, isTrue);
  });
}
