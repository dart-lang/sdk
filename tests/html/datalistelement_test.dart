// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('datalistelement_dataview_test');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  var div;

  setUp(() {
      div = new DivElement();
      document.body.nodes.add(div);
      div.innerHTML = """
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


  test('is', () {
      var list = document.query('#browsers');
      expect(list is DataListElement);
  });

  test('list', () {
      var list = document.query('#browsers');
      var input = document.query('#input');
      expect(input.list, list);
  });

  test('options', () {
      var options = document.query('#browsers')
          .queryAll('option');  // Uses DataListElement.
      expect(options.length, 5);
  });

  test('create', () {
      var list = new DataListElement();
      expect(list is DataListElement);
    });
}
