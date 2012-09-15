// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

#library('NodeListTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  var div = new DivElement();
  div.id = 'test';
  document.body.nodes.add(div);

  div.nodes.addAll([
      new DivElement(),
      new CanvasElement(),
      new DivElement(),
      new Text('Hello'),
      new DivElement(),
      new Text('World'),
      new CanvasElement()]);

  test('queryAll', () {
      List<Node> all = queryAll('*');
      for (var e in all) {
        expect(e is Element, isTrue);
      }
    });

  test('document.queryAll', () {
      List<Element> all1 = queryAll('*');
      List<Element> all2 = document.queryAll('*');
      expect(all1.length, equals(all2.length));
      for (var i = 0; i < all1.length; ++i) {
        expect(all1[i], equals(all2[i]));
      }
    });

  test('queryAll-canvas', () {
      List<CanvasElement> all = queryAll('canvas');
      for (var e in all) {
        expect(e is CanvasElement, isTrue);
      }
      expect(all.length, equals(2));
    });

  test('queryAll-filter', () {
      List<Element> all = queryAll('*');
      List<CanvasElement> canvases = all.filter((e) => e is CanvasElement);
      for (var e in canvases) {
        expect(e is CanvasElement, isTrue);
      }
      expect(canvases.length, equals(2));
    });

  test('node.queryAll', () {
      List<Element> list = div.queryAll('*');
      expect(list.length, equals(5));
      expect(list[0] is DivElement, isTrue);
      expect(list[1] is CanvasElement, isTrue);
      expect(list[2] is DivElement, isTrue);
      expect(list[3] is DivElement, isTrue);
      expect(list[4] is CanvasElement, isTrue);
    });

  test('immutable', () {
      List<Element> list = div.queryAll('*');
      int len = list.length;
      expect(() { list.add(new DivElement()); }, throwsException);
      expect(list.length, equals(len));
    });
}
