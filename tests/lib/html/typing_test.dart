// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

main() {
  var isStyleSheetList = predicate(
    (x) => x is List<StyleSheet>,
    'is a List<StyleSheet>',
  );

  test('NodeList', () {
    List<Element> asList = window.document.querySelectorAll('body');
    // Check it's Iterable
    int counter = 0;
    for (Element node in window.document.querySelectorAll('body')) {
      counter++;
    }
    expect(counter, 1);
    counter = 0;
    window.document.querySelectorAll('body').forEach((e) {
      counter++;
    });
    expect(counter, 1);
  });

  test('StyleSheetList', () {
    var document = window.document as HtmlDocument;
    List<StyleSheet> asList = document.styleSheets!;
    expect(asList, isStyleSheetList);
    // Check it's Iterable.
    int counter = 0;
    for (StyleSheet styleSheet in asList) {
      counter++;
    }

    // There is one style sheet from the test framework.
    expect(counter, 1);
  });
}
