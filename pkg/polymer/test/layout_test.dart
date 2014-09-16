// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.layout_test;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);
  
  getTestElements(test) {
    var t = document.getElementById(test);
    return {
        'h1': t.querySelector('[horizontal] > [flex]').getComputedStyle(),
        'h2': t.querySelector('[horizontal] > [flex][sized]')
            .getComputedStyle(),
        'v1': t.querySelector('[vertical] > [flex]').getComputedStyle(),
        'v2': t.querySelector('[vertical] > [flex][sized]').getComputedStyle()
    };
  }

  // no-size container tests

  test('flex-layout-attributies', () {
    var elements = getTestElements('test1');
    expect(elements['h1'].width, elements['h2'].width,
        reason: 'unsized container: horizontal flex items have same width');
    expect(elements['v1'].height, '0px',
        reason: 'unsized container: vertical flex items have no intrinsic '
                'height');
  });
  
  test('flex auto layout attributes', () {
    var elements = getTestElements('test2');
    expect(elements['h1'].width, isNot(elements['h2'].width), 
        reason: 'unsized container: horizontal flex auto items have intrinsic '
                'width + flex amount');
    expect(elements['v1'].height, isNot('0px'),
        reason: 'unsized container: vertical flex auto items have intrinsic '
                'height');
  });

  test('flex auto-vertical layout attributes', () {
    var elements = getTestElements('test3');
    expect(elements['h1'].width, elements['h2'].width, 
        reason: 'unsized container: horizontal flex auto-vertical items have '
                'same width');
    expect(elements['v1'].height, isNot('0px'),
        reason: 'unsized container: vertical flex auto-vertical items have '
                'intrinsic height');
  });

  // Sized container tests

  test('flex layout attributes', () {
    var elements = getTestElements('test4');
    expect(elements['h1'].width, elements['h2'].width,
        reason: 'sized container: horizontal flex items have same width');
    expect(elements['v1'].height, elements['v2'].height,
        reason: 'sized container: vertical flex items have same height');
  });

  test('flex auto layout attributes', () {
    var elements = getTestElements('test5');
    expect(elements['h1'].width, isNot(elements['h2'].width),
        reason: 'sized container: horizontal flex auto items have intrinsic '
                'width + flex amount');
    expect(elements['v1'].height, isNot('0px'),
        reason: 'sized container: vertical flex auto items have intrinsic '
                'height');
    expect(elements['v1'].height, isNot(elements['v2'].height),
        reason: 'sized container: vertical flex auto items have intrinsic '
                'width + flex amount');
  });

  test('flex auto-vertical layout attributes', () {
    var elements = getTestElements('test3');
    expect(elements['h1'].width, elements['h2'].width,
        reason: 'unsized container: horizontal flex auto-vertical items have '
                'same width');
    expect(elements['v1'].height, isNot('0px'),
        reason: 'sized container: vertical flex auto-vertical items have '
                'intrinsic height');
    expect(elements['v1'].height, isNot(elements['v2'].height),
        reason: 'sized container: vertical flex auto-vertical items have '
                'intrinsic width + flex amount');
  });

});
