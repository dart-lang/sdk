// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that poi.dart can serialize a scope.

library trydart.serialize_test;

import 'dart:io' show
    Platform;

import 'dart:async' show
    Future;

import 'dart:convert' show
    JSON;

import 'package:try/poi/poi.dart' as poi;

import 'package:async_helper/async_helper.dart';

import 'package:expect/expect.dart';

import 'package:compiler/src/elements/elements.dart' show
    Element;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

Future testInteresting() {
  poi.cachedCompiler = null;
  Uri script = Platform.script.resolve('data/interesting.dart');
  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();

  int position = 263;

  Future future = poi.runPoi(script, position, handler.provider, handler);
  return future.then((Element element) {
    Uri foundScript = element.compilationUnit.script.resourceUri;
    Expect.stringEquals('$script', '$foundScript');
    Expect.stringEquals('fisk', element.name);

    String scope = poi.scopeInformation(element, position);
    Expect.stringEquals(
        JSON.encode(expectedInteresting), JSON.encode(JSON.decode(scope)),
        scope);
    return testSubclass(handler);
  });
}

Future testSubclass(FormattingDiagnosticHandler handler) {
  poi.cachedCompiler = null;
  int position = 506;

  Uri script = Platform.script.resolve('data/subclass.dart');

  Future future = poi.runPoi(script, position, handler.provider, handler);
  return future.then((Element element) {
    Uri foundScript = element.compilationUnit.script.resourceUri;
    Expect.stringEquals('$script', '$foundScript');
    Expect.stringEquals('instanceMethod2', element.name);

    String scope = poi.scopeInformation(element, position);
    Expect.stringEquals(
        JSON.encode(expectedSubclass), JSON.encode(JSON.decode(scope)), scope);

    return testAbstractField(handler);
  });
}

Future testAbstractField(FormattingDiagnosticHandler handler) {
  poi.cachedCompiler = null;
  int position = 321;

  Uri script = Platform.script.resolve('data/abstract_field.dart');

  Future future = poi.runPoi(script, position, handler.provider, handler);
  return future.then((Element element) {
    Uri foundScript = element.compilationUnit.script.resourceUri;
    Expect.stringEquals('$script', '$foundScript');
    Expect.stringEquals('method', element.name);

    String scope = poi.scopeInformation(element, position);
    Expect.stringEquals(
        JSON.encode(expectedAbstractField), JSON.encode(JSON.decode(scope)),
        scope);
  });
}

void main() {
  asyncTest(testInteresting);
}

final expectedInteresting = {
  "name": "fisk",
  "kind": "function",
  "type": "() -> dynamic",
  "enclosing": {
    "name": "Foo",
    "kind": "class side",
    "members": [
      {
        "kind": "generative_constructor",
        "type": "() -> Foo"
      }
    ],
    "enclosing": {
      "name": "Foo",
      "kind": "instance side",
      "members": [
        {
          "name": "fisk",
          "kind": "function",
          "type": "() -> dynamic"
        },
        {
          "name": "hest",
          "kind": "function",
          "type": "() -> dynamic"
        },
      ],
      "enclosing": {
        "name": "interesting",
        "kind": "library",
        "members": [
          {
            "name": "Foo",
            "kind": "class"
          },
          {
            "name": "main",
            "kind": "function",
            "type": "() -> dynamic"
          }
        ],
        "enclosing": {
          "kind": "imports",
          "members": coreImports,
          "enclosing": object,
        }
      }
    }
  }
};

final expectedSubclass = {
  "name": "instanceMethod2",
  "kind": "function",
  "type": "() -> dynamic",
  "enclosing": {
    "name": "C",
    "kind": "class side",
    "members": [
      {
        "name": "staticMethod1",
        "kind": "function",
        "type": "() -> dynamic"
      },
      {
        "name": "staticMethod2",
        "kind": "function",
        "type": "() -> dynamic"
      },
      {
        "kind": "generative_constructor",
        "type": "() -> C"
      }
    ],
    "enclosing": {
      "name": "C",
      "kind": "instance side",
      "members": [
        {
          "name": "instanceMethod1",
          "kind": "function",
          "type": "() -> dynamic"
        },
        {
          "name": "instanceMethod2",
          "kind": "function",
          "type": "() -> dynamic"
        }
      ],
      "enclosing": {
        "name": "subclass",
        "kind": "library",
        "members": [
          {
            "name": "S",
            "kind": "class"
          },
          {
            "name": "C",
            "kind": "class"
          },
          {
            "name": "main",
            "kind": "function",
            "type": "() -> dynamic"
          },
          {
            "name": "p",
            "kind": "prefix"
          }
        ],
        "enclosing": {
          "kind": "imports",
          "members": [
            {
              "name": "Foo",
              "kind": "class"
            },
            {
              "name": "main",
              "kind": "function",
              "type": "() -> dynamic"
            },
          ]..addAll(coreImports),
          "enclosing": {
            "name": "S",
            "kind": "instance side",
            "members": [
              {
                "name": "superMethod1",
                "kind": "function",
                "type": "() -> dynamic"
              },
              {
                "name": "superMethod2",
                "kind": "function",
                "type": "() -> dynamic"
              },
            ],
            "enclosing": {
              "name": "P",
              "kind": "instance side",
              "members": [
                {
                  "name": "pMethod1",
                  "kind": "function",
                  "type": "() -> dynamic"
                },
                {
                  "name": "pMethod2",
                  "kind": "function",
                  "type": "() -> dynamic"
                },
                {
                  "name": "_pMethod1",
                  "kind": "function",
                  "type": "() -> dynamic"
                },
                {
                  "name": "_pMethod2",
                  "kind": "function",
                  "type": "() -> dynamic"
                },
              ],
              "enclosing": object,
            }
          }
        }
      }
    }
  }
};

final expectedAbstractField = {
  "name": "method",
  "kind": "function",
  "type": "() -> dynamic",
  "enclosing": {
    "name": "A",
    "kind": "class side",
    "members": [
      {
        "kind": "generative_constructor",
        "type": "() -> A"
      }
    ],
    "enclosing": {
      "name": "A",
      "kind": "instance side",
      "members": [
        {
          "name": "foo",
          "kind": "getter"
        },
        {
          "name": "foo",
          "kind": "setter"
        },
        {
          "name": "method",
          "kind": "function",
          "type": "() -> dynamic"
        }
      ],
      "enclosing": {
        "name": "abstract_field",
        "kind": "library",
        "members": [
          {
            "name": "A",
            "kind": "class"
          },
          {
            "name": "bar",
            "kind": "getter"
          },
          {
            "name": "bar",
            "kind": "getter"
          },
          {
            "name": "main",
            "kind": "function",
            "type": "() -> dynamic"
          }
        ],
        "enclosing": {
          "kind": "imports",
          "members": coreImports,
          "enclosing": object
        },
      },
    },
  },
};

final coreImports = [
  {
    "name": "Deprecated",
    "kind": "class"
  },
  {
    "name": "deprecated",
    "kind": "field",
    "type": "Deprecated"
  },
  {
    "name": "override",
    "kind": "field",
    "type": "Object"
  },
  {
    "name": "proxy",
    "kind": "field",
    "type": "Object"
  },
  {
    "name": "bool",
    "kind": "class"
  },
  {
    "name": "Comparator",
    "kind": "typedef"
  },
  {
    "name": "Comparable",
    "kind": "class"
  },
  {
    "name": "DateTime",
    "kind": "class"
  },
  {
    "name": "double",
    "kind": "class"
  },
  {
    "name": "Duration",
    "kind": "class"
  },
  {
    "name": "Error",
    "kind": "class"
  },
  {
    "name": "AssertionError",
    "kind": "class"
  },
  {
    "name": "TypeError",
    "kind": "class"
  },
  {
    "name": "CastError",
    "kind": "class"
  },
  {
    "name": "NullThrownError",
    "kind": "class"
  },
  {
    "name": "ArgumentError",
    "kind": "class"
  },
  {
    "name": "RangeError",
    "kind": "class"
  },
  {
    "name": "IndexError",
    "kind": "class"
  },
  {
    "name": "FallThroughError",
    "kind": "class"
  },
  {
    "name": "AbstractClassInstantiationError",
    "kind": "class"
  },
  {
    "name": "NoSuchMethodError",
    "kind": "class"
  },
  {
    "name": "UnsupportedError",
    "kind": "class"
  },
  {
    "name": "UnimplementedError",
    "kind": "class"
  },
  {
    "name": "StateError",
    "kind": "class"
  },
  {
    "name": "ConcurrentModificationError",
    "kind": "class"
  },
  {
    "name": "OutOfMemoryError",
    "kind": "class"
  },
  {
    "name": "StackOverflowError",
    "kind": "class"
  },
  {
    "name": "CyclicInitializationError",
    "kind": "class"
  },
  {
    "name": "Exception",
    "kind": "class"
  },
  {
    "name": "FormatException",
    "kind": "class"
  },
  {
    "name": "IntegerDivisionByZeroException",
    "kind": "class"
  },
  {
    "name": "Expando",
    "kind": "class"
  },
  {
    "name": "Function",
    "kind": "class"
  },
  {
    "name": "identical",
    "kind": "function",
    "type": "(Object, Object) -> bool"
  },
  {
    "name": "identityHashCode",
    "kind": "function",
    "type": "(Object) -> int"
  },
  {
    "name": "int",
    "kind": "class"
  },
  {
    "name": "Invocation",
    "kind": "class"
  },
  {
    "name": "Iterable",
    "kind": "class"
  },
  {
    "name": "BidirectionalIterator",
    "kind": "class"
  },
  {
    "name": "Iterator",
    "kind": "class"
  },
  {
    "name": "List",
    "kind": "class"
  },
  {
    "name": "Map",
    "kind": "class"
  },
  {
    "name": "Null",
    "kind": "class"
  },
  {
    "name": "num",
    "kind": "class"
  },
  {
    "name": "Object",
    "kind": "class"
  },
  {
    "name": "Pattern",
    "kind": "class"
  },
  {
    "name": "print",
    "kind": "function",
    "type": "(Object) -> void"
  },
  {
    "name": "Match",
    "kind": "class"
  },
  {
    "name": "RegExp",
    "kind": "class"
  },
  {
    "name": "Set",
    "kind": "class"
  },
  {
    "name": "Sink",
    "kind": "class"
  },
  {
    "name": "StackTrace",
    "kind": "class"
  },
  {
    "name": "Stopwatch",
    "kind": "class"
  },
  {
    "name": "String",
    "kind": "class"
  },
  {
    "name": "Runes",
    "kind": "class"
  },
  {
    "name": "RuneIterator",
    "kind": "class"
  },
  {
    "name": "StringBuffer",
    "kind": "class"
  },
  {
    "name": "StringSink",
    "kind": "class"
  },
  {
    "name": "Symbol",
    "kind": "class"
  },
  {
    "name": "Type",
    "kind": "class"
  },
  {
    "name": "Uri",
    "kind": "class"
  }
];

final object = {
  "name": "Object",
  "kind": "instance side",
  "members": [
    {
      "name": "==",
      "kind": "function",
      "type": "(dynamic) -> bool"
    },
    {
      "name": "hashCode",
      "kind": "getter"
    },
    {
      "name": "toString",
      "kind": "function",
      "type": "() -> String"
    },
    {
      "name": "noSuchMethod",
      "kind": "function",
      "type": "(Invocation) -> dynamic"
    },
    {
      "name": "runtimeType",
      "kind": "getter"
    }
  ]
};
