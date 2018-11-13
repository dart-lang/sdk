// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library mock;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS('Node')
class Node {}

@JS('HTMLDocument')
class Document extends Node {
  external Element get body;
}

@JS()
external get foo;

@JS()
external Document get document;

@JS('Element')
class Element extends Node {
  external String get tagName;
}

class MockDocument implements Document {
  final Element body = new MockElement();
}

class MockElement implements Element {
  final tagName = 'MockBody';
}

void main() {
  test('js', () {
    var f = foo;
    expect(f, isNull);

    var doc = document;
    expect(doc is Document, isTrue);
    // Fails in dart2js
    //expect(doc is! Element, isTrue);

    expect(doc is Node, isTrue);

    expect(doc is! MockDocument, isTrue);
    expect(doc is! MockElement, isTrue);
  });

  test('mock', () {
    var doc = new MockDocument();
    expect(doc is Document, isTrue);
    // Fails in dart2js
    // expect(doc is! Element, isTrue);
    expect(doc is Node, isTrue);

    var body = doc.body;
    // Fails in dart2js
    // expect(body is! Document, isTrue);
    expect(body is Element, isTrue);
    expect(body is Node, isTrue);
  });
}
