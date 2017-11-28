// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('indexedAccessTest', () {
    // FIXME: we need some massaging to dart:html to enable HTMLOptionsCollection.add
    // and hence programatic building of collection.
    SelectElement selectElement = new Element.html('''
      <select>
        <option value="0">Option0</option>
        <option value="1">Option1</option>
        <option value="2">Option2</option>
      ''');
    final optionsCollection = selectElement.options;

    expect(optionsCollection[0].value, equals('0'));
    expect(optionsCollection[1].value, equals('1'));
    expect(optionsCollection[2].value, equals('2'));

    expect(optionsCollection[0].text, equals('Option0'));
    expect(optionsCollection[1].text, equals('Option1'));
    expect(optionsCollection[2].text, equals('Option2'));

    expect(() {
      (optionsCollection as dynamic)[0] = 1;
    }, throws);

    // OPTIONALS optionsCollection[0] = new OptionElement(value: '42', data: 'Option42');
    expect(() {
      optionsCollection[0] = new OptionElement(data: 'Option42', value: '42');
    }, throws);
  });
}
