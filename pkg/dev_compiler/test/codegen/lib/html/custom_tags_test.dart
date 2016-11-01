// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

import 'utils.dart';

main() {
  test('create via custom tag', () {
    var element = new Element.tag('x-basic1')..id = 'basic1';
    document.body.nodes.add(element);

    var queryById = query('#basic1');
    expect(queryById, equals(element));

    var queryByTag = queryAll('x-basic1');
    expect(queryByTag.length, equals(1));
    expect(queryByTag[0], equals(element));
  });

  test('custom inner html', () {
    var element = new DivElement();
    element.setInnerHtml("<x-basic2 id='basic2'></x-basic2>",
        treeSanitizer: new NullTreeSanitizer());
    document.body.nodes.add(element);

    var queryById = query('#basic2');
    expect(queryById is Element, isTrue);

    var queryByTag = queryAll('x-basic2');
    expect(queryByTag.length, equals(1));
    expect(queryByTag[0], equals(queryById));
  });

  test('type extension inner html', () {
    var element = new DivElement();
    element.setInnerHtml("<div is='x-basic3' id='basic3'></div>",
        treeSanitizer: new NullTreeSanitizer());
    document.body.nodes.add(element);

    var queryById = query('#basic3');
    expect(queryById is DivElement, isTrue);
  });
}
