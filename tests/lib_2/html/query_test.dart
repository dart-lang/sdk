// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
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
    Element e = querySelector('#testcanvas');
    expect(e, isNotNull);
    expect(e.id, 'testcanvas');
    expect(e, isCanvasElement);
    expect(e, canvas);
  });

  test('query (None)', () {
    Element e = querySelector('#nothere');
    expect(e, isNull);
  });

  test('queryAll (One)', () {
    List l = querySelectorAll('canvas');
    expect(l.length, 1);
    expect(l[0], canvas);
  });

  test('queryAll (Multiple)', () {
    List l = querySelectorAll('img');
    expect(l.length, 2);
    expect(l[0], isImageElement);
    expect(l[1], isImageElement);
    expect(l[0] == l[1], isFalse);
  });

  test('queryAll (None)', () {
    List l = querySelectorAll('video');
    expect(l.isEmpty, isTrue);
  });
}
