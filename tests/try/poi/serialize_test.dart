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

import 'package:compiler/implementation/elements/elements.dart' show
    Element;

import 'package:compiler/implementation/source_file_provider.dart' show
    FormattingDiagnosticHandler;

Future testPoi() {
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
        JSON.encode(expected), JSON.encode(JSON.decode(scope)), scope);
  });
}

void main() {
  asyncTest(testPoi);
}

final expected = {
  "name": "fisk",
  "kind": "function",
  "type": "() -> dynamic",
  "enclosing": {
    "name": "Foo",
    "kind": "class",
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
      {
        "name": "",
        "kind": "generative_constructor",
        "type": "() -> Foo"
      }
    ],
    "enclosing": {
      "name": "interesting",
      "kind": "library",
      "members": [
        {
          "name": "main",
          "kind": "function",
          "type": "() -> dynamic"
        },
        {
          "name": "Foo",
          "kind": "class"
        }
      ]
    }
  }
};
