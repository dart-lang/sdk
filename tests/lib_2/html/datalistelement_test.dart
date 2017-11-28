// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isDataListElement =
      predicate((x) => x is DataListElement, 'is a DataListElement');

  var div;

  setUp(() {
    div = new DivElement();
    document.body.append(div);
    div.innerHtml = """
<input id="input" list="browsers" />
<datalist id="browsers">
  <option value="Chrome">
  <option value="Firefox">
  <option value="Internet Explorer">
  <option value="Opera">
  <option value="Safari">
</datalist>
""";
  });

  tearDown(() {
    document.body.nodes.removeLast();
  });

  // Support is checked in element_types test.
  var expectation = DataListElement.supported ? returnsNormally : throws;

  test('is', () {
    expect(() {
      var list = document.query('#browsers');
      expect(list, isDataListElement);
    }, expectation);
  });

  test('list', () {
    expect(() {
      var list = document.query('#browsers') as DataListElement;
      var input = document.query('#input') as InputElement;
      expect(input.list, list);
    }, expectation);
  });

  test('options', () {
    expect(() {
      var options = (document.query('#browsers') as DataListElement).options;
      expect(options.length, 5);
    }, expectation);
  });

  test('create', () {
    expect(() {
      var list = new DataListElement();
      expect(list, isDataListElement);
    }, expectation);
  });
}
