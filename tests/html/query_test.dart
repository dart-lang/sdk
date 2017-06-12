// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library QueryTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  final div = new DivElement();
  final canvas = new CanvasElement(width: 200, height: 200);
  canvas.id = 'testcanvas';
  final element = new Element.html("<div><br/><img/><input/><img/></div>");
  document.body.nodes.addAll([div, canvas, element]);

  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isImageElement =
      predicate((x) => x is ImageElement, 'is an ImageElement');

  test('query', () {
    Element e = query('#testcanvas');
    expect(e, isNotNull);
    expect(e.id, 'testcanvas');
    expect(e, isCanvasElement);
    expect(e, canvas);
  });

  test('query (None)', () {
    Element e = query('#nothere');
    expect(e, isNull);
  });

  test('queryAll (One)', () {
    List l = queryAll('canvas');
    expect(l.length, 1);
    expect(l[0], canvas);
  });

  test('queryAll (Multiple)', () {
    List l = queryAll('img');
    expect(l.length, 2);
    expect(l[0], isImageElement);
    expect(l[1], isImageElement);
    expect(l[0], isNot(equals(l[1])));
  });

  test('queryAll (None)', () {
    List l = queryAll('video');
    expect(l.isEmpty, isTrue);
  });
}
