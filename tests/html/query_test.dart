// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('QueryTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  final div = new DivElement();
  final canvas = new CanvasElement(width: 200, height: 200);
  canvas.id = 'testcanvas';
  final element =
      new Element.html("<div><br/><img/><input/><img/></div>");
  document.body.nodes.addAll([div, canvas,  element]);
  

  test('query', () {
      Element e = query('#testcanvas');
      Expect.isNotNull(e);
      Expect.stringEquals('testcanvas', e.id);
      Expect.isTrue(e is CanvasElement);
      Expect.equals(canvas, e);
    });

  test('query (None)', () {
      Element e = query('#nothere');
      Expect.isNull(e);
    });

  test('queryAll (One)', () {
      List l = queryAll('canvas');
      Expect.equals(1, l.length);
      Expect.equals(canvas, l[0]);
    });


  test('queryAll (Multiple)', () {
      List l = queryAll('img');
      Expect.equals(2, l.length);
      Expect.isTrue(l[0] is ImageElement);
      Expect.isTrue(l[1] is ImageElement);
      Expect.notEquals(l[0], l[1]);
    });

  test('queryAll (None)', () {
      List l = queryAll('video');
      Expect.isTrue(l.isEmpty());
    });
}
