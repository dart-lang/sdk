// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('selectelement_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('selectedOptions', () {
    var element = new SelectElement();
    var options = [
      new OptionElement(),
      new OptionElement('data', 'two', false, true),
      new OptionElement('data', 'two', false, true),
      new OptionElement(),
    ];
    element.elements.addAll(options);
    expect(element.selectedOptions.length, 1);
    expect(element.selectedOptions[0] == options[2]);
  });

  test('multiple selectedOptions', () {
    var element = new SelectElement();
    element.multiple = true;
    var options = [
      new OptionElement(),
      new OptionElement('data', 'two', false, true),
      new OptionElement('data', 'two', false, true),
      new OptionElement(),
    ];
    element.elements.addAll(options);
    expect(element.selectedOptions.length, 2);
    expect(element.selectedOptions[0] == options[1]);
    expect(element.selectedOptions[1] == options[2]);
  });
}
