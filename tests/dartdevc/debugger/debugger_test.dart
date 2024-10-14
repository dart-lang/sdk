/// Debugger custom formatter tests.
/// If the tests fail, paste the expected output into the golden file and audit
/// the diff to ensure changes are expected.
///
/// Currently only DDC supports debugging objects with custom formatters
/// but it is reasonable to add support to Dart2JS in the future.
@JS()
library debugger_test;

import 'dart:html';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/async_helper.dart';
import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js.dart' as pkgJs;

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

class FormattedObject {
  FormattedObject(this.object, this.config);

  JSAny? object;
  JSAny? config;
}

@JS('JSON.stringify')
external String? stringify(JSAny? value, [JSFunction replacer, int space]);

@JS('Object.getOwnPropertyNames')
external JSArray<JSString> getOwnPropertyNames(JSObject obj);

@JS()
external JSArray? get devtoolsFormatters;

@JS('Object.getPrototypeOf')
external Prototype getPrototypeOf(JSAny obj);

extension type FormattedJSObject._(JSObject _) implements JSObject {
  external JSAny? get object;
  external JSAny? get config;
}

// We use `JSAny` here since we're using this to interop with the prototype of a
// Dart class, which isn't a `JSObject`.
extension type Prototype._(JSAny _) implements JSAny {
  external JSAny get constructor;
}

extension type FooBar._(JSObject _) implements JSObject {
  external FooBar({String foo});
}

@pkgJs.JS()
class PackageJSClass<T> {
  external factory PackageJSClass(T x);
}

T unsafeCast<T extends JSAny?>(Object? object) {
  // This is improper interop code. However, this test mixes Dart and JS values.
  // Since this is only ever run on DDC, this is okay, but we should be
  // deliberate about where we're mixing Dart and JS values.
  return object as T;
}

// Replacer normalizes file names that could vary depending on the test runner
// styles.
JSAny? replacer(String key, JSAny? externalValue) {
  // The values for keys with name 'object' may be arbitrary Dart nested
  // Objects so are not safe to stringify.
  if (key == 'object') return '<OBJECT>'.toJS;
  if (externalValue.isA<JSString>()) {
    final value = (externalValue as JSString).toDart;
    if (value.contains('dart_sdk.js')) return '<DART_SDK>'.toJS;
    if (new RegExp(r'[.](js|dart|html)').hasMatch(value)) {
      return '<FILE>'.toJS;
    }
    // Normalize the name of the `Event` type as it appears in this test.
    // The new type system preserves the original name from the Dart source.
    // TODO(48585): Remove when no longer running with the old type system.
    return value.replaceAll(r'Event$', 'Event').toJS;
  }
  return externalValue;
}

String? format(JSAny? value) {
  // Avoid double-escaping strings.
  if (value.isA<JSString>()) return (value as JSString).toDart;
  return stringify(value, replacer.toJS, 4);
}

/// Extract all object tags from a json ml expression to enable
/// calling the custom formatter on the extracted object tag.
List<FormattedObject> extractNestedFormattedObjects(JSAny json) {
  var ret = <FormattedObject>[];
  if (json.isA<JSString>() || json.isA<JSBoolean>() || json.isA<JSNumber>()) {
    return ret;
  }
  if (json.isA<JSArray>()) {
    for (var i = 0; i < (json as JSArray<JSAny>).length; i++) {
      ret.addAll(extractNestedFormattedObjects(json[i]));
    }
    return ret;
  }

  // Must be a JS object. See JsonMLElement in dart:_debugger.
  final jsObject = json as FormattedJSObject;
  final propertyNames = getOwnPropertyNames(jsObject);
  for (var i = 0; i < propertyNames.length; i++) {
    final name = propertyNames[i].toDart;
    if (name == 'object') {
      // Found a nested formatted object.
      ret.add(new FormattedObject(jsObject.object, jsObject.config));
      return ret;
    }
    ret.addAll(extractNestedFormattedObjects(jsObject[name]!));
  }
  return ret;
}

main() async {
  asyncStart();
  if (devtoolsFormatters == null) {
    print("Warning: no devtools custom formatters specified. Skipping tests.");
    return;
  }

  // Cache blocker is a workaround for:
  // https://code.google.com/p/dart/issues/detail?id=11834
  var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
  var goldenUrl = '/root_dart/tests/dartdevc/debugger/'
      'debugger_test_golden.txt?cacheBlock=$cacheBlocker';

  String? golden;
  try {
    golden = (await HttpRequest.getString(goldenUrl)).trim();
  } catch (e) {
    print("Warning: couldn't load golden file from $goldenUrl");
  }

  document.body!.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
window.PackageJSClass = function PackageJSClass(x) {
  this.x = x;
};
""");

  var _devtoolsFormatter = (devtoolsFormatters![0]
          as ExternalDartReference<_debugger.JsonMLFormatter>)
      .toDartObject;

  var actual = new StringBuffer();

  // Accumulate the entire expected custom formatted data as a single
  // massive string buffer so it is simple to update expectations when
  // modifying the formatting code.
  // Otherwise a small formatting change would result in tweaking lots
  // of expectations.
  // The verify golden match test cases does the final comparison of golden
  // to expected output.
  void addGolden(String name, JSAny value) {
    var text = format(value);
    actual.write('Test: $name\n'
        'Value:\n'
        '$text\n'
        '-----------------------------------\n');
  }

  void addFormatterGoldens(String name, Object? object, [Object? config]) {
    addGolden(
        '$name formatting header', _devtoolsFormatter.header(object, config));
    addGolden('$name formatting body', _devtoolsFormatter.body(object, config));
  }

  // Include goldens for the nested [[class]] definition field.
  void addNestedFormatterGoldens(String name, Object obj) {
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
  void addAllNestedFormatterGoldens(String name, Object obj) {
    addGolden('$name header', _devtoolsFormatter.header(obj, null));
    // The cast to `JSAny` is safe as `header` and `body` should always return
    // JS values.
    var body = _devtoolsFormatter.body(obj, null) as JSAny;
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

    var s = new Set()
      ..add("foo")
      ..add(42)
      ..add(true);
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

    addFormatterGoldens('Function with function arguments', addEventListener);

    // Closure
    addGolden('dart:html method', unsafeCast(window.addEventListener));

    // Get a reference to the JS constructor for a Dart class.
    // This tracks a regression bug where overly verbose and confusing output
    // was shown for this case.
    var testClass = new TestClass(17);
    var dartConstructor = getPrototypeOf(unsafeCast(testClass)).constructor;
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
    var object = FooBar(foo: 'bar');
    // Make sure we don't apply the Dart custom formatter to JS interop objects.
    expect(_devtoolsFormatter.header(object, null), isNull);
  });

  group('Module formatting', () {
    var moduleNames = _debugger.getModuleNames();
    var testModuleName = "debugger_test";
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
    // TODO(jmesserly): this includes a timeStamp, so it varies each run.
    //addNestedFormatterGoldens('MouseEvent', new MouseEvent("click"));
    // This is a good class to test as it has statics and a deep inheritance hierarchy
    addNestedFormatterGoldens('HttpRequest', new HttpRequest());
  });

  group('Generics formatting', () {
    addNestedFormatterGoldens(
        'TestGenericClass', new TestGenericClass<int, List>(42));
    addNestedFormatterGoldens(
        'TestGenericClassJSInterop',
        new TestGenericClass<PackageJSClass<JSString>, int>(
            new PackageJSClass("Hello".toJS)));
  });

  test('verify golden match', () {
    // Warning: all other test groups must have run for this test to be meaningful
    var actualStr = actual.toString().trim();

    if (actualStr != golden) {
      var helpMessage =
          'Debugger output does not match the golden data found in:\n'
          'tests/dartdevc/debugger/debugger_test_golden.txt\n'
          'The new golden data is copied to the clipboard when you click on '
          'this window.\n'
          'Please update the golden file with the following output and review '
          'the diff using your favorite diff tool to make sure the custom '
          'formatting output has not regressed.';
      print(helpMessage);
      // Copy text to clipboard on page click. We can't copy to the clipboard
      // without a click due to Chrome security.
      var textField = new Element.tag('textarea') as TextAreaElement;
      textField.maxLength = 100000000;
      textField.text = actualStr;
      textField.style
        ..width = '800px'
        ..height = '400px';
      document.body!.append(new Element.tag('h3')
        ..innerHtml = helpMessage.replaceAll('\n', '<br>'));
      document.body!.append(textField);
      document.body!.onClick.listen((_) {
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
    asyncEnd();
  });
}
