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
    document.body!.append(div);
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
    document.body!.nodes.removeLast();
  });

  test('is', () {
    try {
      var list = document.querySelector('#browsers');
      expect(list, isDataListElement);
    } catch (e) {
      expect(DataListElement.supported, false);
    }
  });

  test('list', () {
    try {
      var list = document.querySelector('#browsers') as DataListElement;
      var input = document.querySelector('#input') as InputElement;
      expect(input.list, list);
    } catch (e) {
      expect(DataListElement.supported, false);
    }
  });

  test('options', () {
    try {
      var options =
          (document.querySelector('#browsers') as DataListElement).options!;
      expect(options.length, 5);
    } catch (e) {
      expect(DataListElement.supported, false);
    }
  });

  test('create', () {
    try {
      var list = new DataListElement();
      expect(list, isDataListElement);
    } catch (e) {
      expect(DataListElement.supported, false);
    }
  });
}
