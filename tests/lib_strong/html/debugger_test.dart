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

main() {
  if (devtoolsFormatters == null) {
    print("Warning: no devtools custom formatters specified. Skipping tests.");
    return;
  }
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
    var testModuleName = "lib/html/debugger_test";
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
    // This is a good class to test as it has statics and a deep inheritance heirarchy
    addNestedFormatterGoldens('HttpRequest', new HttpRequest());
  });

  test('verify golden match', () {
    // Warning: all other test groups must have run for this test to be meaningful
    print("Actual:##############\n$actual\n#################");

    expect(actual.toString().trim(), equals(expectedGolden().trim()));
  });
}

/// The golden custom formatter output is placed at the bottom of the file
/// to simplify replacing the  golden data when the custom formatter code is
/// changed.
///
/// This value is placed in a function rather than a field to avoid a recursive
/// program that prints itself issue as the golden includes the formatter output
/// for this library
String expectedGolden() => r"""Test: List<String> formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JSArray<String> length 3"
]
-----------------------------------
Test: List<String> formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "0: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "foo"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "1: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "bar"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "2: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "baz"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: List<Object> instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JSArray<Object> length 3"
]
-----------------------------------
Test: List<Object> instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "0: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "42"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "1: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "bar"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "2: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "true"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: List<Object> definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JSArray<Object> implements List<Object>, JSIndexable<Object>"
]
-----------------------------------
Test: List<Object> definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "markFixedList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "markUnmodifiableList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "add: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "addAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "any: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "asMap: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "checkGrowable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "checkMutable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "clear: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "contains: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "elementAt: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "every: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "expand: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "fillRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "firstWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "fold: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "forEach: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "getRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "indexOf: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "insert: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "insertAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "join: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "lastIndexOf: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "lastWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "map: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "reduce: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "remove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeAt: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeLast: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "replaceRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "retainWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "setAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "setRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "shuffle: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "singleWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "skip: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "skipWhile: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "sort: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "sublist: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "take: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "takeWhile: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "toList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "toSet: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "where: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_get: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_removeWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_set: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: List<int> large instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JSArray<int> length 200"
]
-----------------------------------
Test: List<int> large instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": ""
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": ""
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: List<int> large definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JSArray<int> implements List<int>, JSIndexable<int>"
]
-----------------------------------
Test: List<int> large definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "markFixedList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "markUnmodifiableList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "add: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "addAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "any: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "asMap: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "checkGrowable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "checkMutable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "clear: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "contains: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "elementAt: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "every: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "expand: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "fillRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "firstWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "fold: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "forEach: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "getRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "indexOf: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "insert: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "insertAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "join: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "lastIndexOf: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "lastWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "map: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "reduce: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "remove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeAt: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeLast: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "removeWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "replaceRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "retainWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "setAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "setRange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "shuffle: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "singleWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "skip: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "skipWhile: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "sort: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "sublist: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "take: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "takeWhile: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "toList: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "toSet: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "where: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_get: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_removeWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_set: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Iterable instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "MappedListIterable<String, String> length 3"
]
-----------------------------------
Test: Iterable instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "0: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "foofoofoofoofoo"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "1: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "barbarbarbarbar"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "2: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "bazbazbazbazbaz"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Iterable definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "MappedListIterable<String, String>"
]
-----------------------------------
Test: Iterable definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "elementAt: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Set instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "_LinkedHashSet length 3"
]
-----------------------------------
Test: Set instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "0: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "foo"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "1: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "42"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "2: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "true"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Set definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "_LinkedHashSet implements LinkedHashSet"
]
-----------------------------------
Test: Set definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_deleteTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_isNumericElement: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_isStringElement: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_newHashTable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_setTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "add: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "contains: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "forEach: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "lookup: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "remove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_add: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_addHashTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_computeHashCode: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_contains: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_filterWhere: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_findBucketIndex: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_getBucket: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_getTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_lookup: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_modified: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_newLinkedCell: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_newSet: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_remove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_removeHashTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_unlinkCell: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_unsupported: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Map<String, int> formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JsLinkedHashMap<String, int> length 3"
]
-----------------------------------
Test: Map<String, int> formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "0: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "1: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "2: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Map<dynamic, dynamic> instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JsLinkedHashMap<Object, Object> length 3"
]
-----------------------------------
Test: Map<dynamic, dynamic> instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "0: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "1: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "2: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Map<dynamic, dynamic> definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "JsLinkedHashMap<Object, Object> implements LinkedHashMap<Object, Object>, InternalMap<Object, Object>"
]
-----------------------------------
Test: Map<dynamic, dynamic> definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_isNumericKey: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_isStringKey: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "addAll: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "clear: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "containsKey: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "containsValue: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "forEach: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalComputeHashCode: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalContainsKey: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalFindBucketIndex: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalGet: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalRemove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "internalSet: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "putIfAbsent: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "remove: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_addHashTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_containsTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_deleteTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_get: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_getBucket: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_getTableBucket: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_getTableCell: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_modified: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_newHashTable: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_newLinkedCell: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_removeHashTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_set: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_setTableEntry: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_unlinkCell: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Function formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "(int, int) -> int"
]
-----------------------------------
Test: Function formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "signature: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "(int, int) -> int"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "JavaScript Function: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "skipDart"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Function with functon arguments formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "(String, (Event) -> bool) -> dynamic"
]
-----------------------------------
Test: Function with functon arguments formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "signature: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "(String, (Event) -> bool) -> dynamic"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "JavaScript Function: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "skipDart"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: dart:html method
Value:
null
-----------------------------------
Test: Raw reference to dart constructor formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "TestClass"
]
-----------------------------------
Test: Raw reference to dart constructor formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    }
]
-----------------------------------
Test: Object formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "Object"
]
-----------------------------------
Test: Object formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "runtimeType: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Type TestClass formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "TestClass"
]
-----------------------------------
Test: Type TestClass formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    }
]
-----------------------------------
Test: Type HttpRequest formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "HttpRequest"
]
-----------------------------------
Test: Type HttpRequest formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    }
]
-----------------------------------
Test: Test library Module header
Value:
null
-----------------------------------
Test: Test library Module body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": ""
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: Test library Module child 0 formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "<FILE>"
]
-----------------------------------
Test: Test library Module child 0 formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "TestClass: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "TestGenericClass: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "devtoolsFormatters: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "replacer: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "format: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "FormattedObject: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "extractNestedFormattedObjects: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "main: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "expectedGolden: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: StackTrace formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "StackTrace"
]
-----------------------------------
Test: StackTrace formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;color: rgb(196, 26, 22);"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "Error"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<DART_SDK>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "<FILE>"
            ]
        ]
    ]
]
-----------------------------------
Test: TestClass instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "TestClass"
]
-----------------------------------
Test: TestClass instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "date: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "17"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "name: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "test class"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "someInt: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "42"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "someObject: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "someString: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "Hello world"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: TestClass definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "TestClass"
]
-----------------------------------
Test: TestClass definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "exampleStaticMethod: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "addOne: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "last: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "nameAndDate: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "returnObject: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: MouseEvent instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "MouseEvent"
]
-----------------------------------
Test: MouseEvent instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "altKey: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "false"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "button: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "buttons: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "client: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "ctrlKey: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "false"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "dataTransfer: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "null"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "fromElement: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "layer: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "metaKey: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "false"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "movement: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "offset: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "<Exception thrown> Unsupported operation: offsetX is only supported on elements"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "page: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "region: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "null"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "relatedTarget: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "screen: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "shiftKey: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "false"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "toElement: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_clientX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_clientY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_get_relatedTarget: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_layerX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_layerY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_movementX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_movementY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_pageX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_pageY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_screenX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_screenY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_webkitMovementX: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "null"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_webkitMovementY: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "null"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: MouseEvent definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "MouseEvent"
]
-----------------------------------
Test: MouseEvent definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_create_1: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_create_2: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_initMouseEvent: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_initMouseEvent_1: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: HttpRequest instance header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "HttpRequest"
]
-----------------------------------
Test: HttpRequest instance body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "onReadyStateChange: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "readyState: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "response: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "responseHeaders: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "responseText: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "responseType: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "responseUrl: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "responseXml: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "status: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "statusText: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "timeout: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "0"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "upload: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "withCredentials: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                "false"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": "color: rgb(136, 19, 145); margin-right: -13px"
                },
                "_get_response: "
            ],
            [
                "span",
                {
                    "style": "margin-left: 13px"
                },
                ""
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
Test: HttpRequest definition formatting header
Value:
[
    "span",
    {
        "style": "background-color: #d9edf7;"
    },
    "HttpRequest"
]
-----------------------------------
Test: HttpRequest definition formatting body
Value:
[
    "ol",
    {
        "style": "list-style-type: none;padding-left: 0px;margin-top: 0px;margin-bottom: 0px;margin-left: 12px;"
    },
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Static members]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "getString: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "postFormData: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "request: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "requestCrossOrigin: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "_create_1: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {},
            [
                "span",
                {
                    "style": ""
                },
                "[[Instance Methods]]"
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "abort: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "getAllResponseHeaders: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "getResponseHeader: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "open: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "overrideMimeType: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "send: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "setRequestHeader: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "none"
                    }
                }
            ]
        ]
    ],
    [
        "li",
        {
            "style": "padding-left: 13px;"
        },
        [
            "span",
            {
                "style": "color: rgb(136, 19, 145); margin-right: -13px"
            },
            "[[base class]]: "
        ],
        [
            "span",
            {
                "style": "margin-left: 13px"
            },
            [
                "object",
                {
                    "object": "<OBJECT>",
                    "config": {
                        "name": "asClass"
                    }
                }
            ]
        ]
    ]
]
-----------------------------------
""";
