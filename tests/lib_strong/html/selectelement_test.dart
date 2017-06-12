// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('selectedOptions', () {
    var element = new SelectElement();
    element.multiple = false;
    var options = [
      new OptionElement(),
      new DivElement(),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new DivElement(),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new OptionElement(),
    ];
    element.children.addAll(options);
    expect(element.selectedOptions.length, 1);
    expect(element.selectedOptions[0], equals(options[4]));
  });

  test('multiple selectedOptions', () {
    var element = new SelectElement();
    element.multiple = true;
    var options = [
      new OptionElement(),
      new DivElement(),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new DivElement(),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new OptionElement(),
      new OptionElement(data: 'data', value: 'two', selected: false),
    ];
    element.children.addAll(options);
    expect(element.selectedOptions.length, 2);
    expect(element.selectedOptions[0], equals(options[2]));
    expect(element.selectedOptions[1], equals(options[4]));
  });

  test('options', () {
    var element = new SelectElement();
    var options = [
      new OptionElement(),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new OptionElement(data: 'data', value: 'two', selected: true),
      new OptionElement(),
    ];
    element.children.addAll(options);
    // Use last to make sure that the list was correctly wrapped.
    expect(element.options.last, equals(options[3]));
  });

  test('optgroup', () {
    var element = new Element.html('<select>'
        '<option>1</option>'
        '<optgroup>'
        '<option>2</option>'
        '</optgroup>'
        '</select>') as SelectElement;

    expect(element.options.length, 2);
    element.selectedIndex = 1;

    var optGroup = element.children[1];
    expect(optGroup is OptGroupElement, isTrue);
    expect((optGroup.children.single as OptionElement).selected, isTrue);
    expect(element.selectedOptions, optGroup.children);
  });
}
