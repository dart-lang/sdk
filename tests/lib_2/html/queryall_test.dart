// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isElement = predicate((x) => x is Element, 'is an Element');
  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isDivElement = predicate((x) => x is DivElement, 'is a isDivElement');

  var div = new DivElement();
  div.id = 'test';
  document.body.append(div);

  div.nodes.addAll([
    new DivElement(),
    new CanvasElement(),
    new DivElement(),
    new Text('Hello'),
    new DivElement(),
    new Text('World'),
    new CanvasElement()
  ]);

  test('queryAll', () {
    List<Node> all = queryAll('*');
    for (var e in all) {
      expect(e, isElement);
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
    var all = queryAll('canvas');
    for (var e in all) {
      expect(e, isCanvasElement);
    }
    expect(all.length, equals(2));
  });

  test('queryAll-contains', () {
    List<Element> all = queryAll('*');
    for (var e in all) {
      expect(all.contains(e), isTrue);
    }
  });

  test('queryAll-where', () {
    List<Element> all = queryAll('*');
    var canvases = all.where((e) => e is CanvasElement);
    for (var e in canvases) {
      expect(e is CanvasElement, isTrue);
    }
    expect(canvases.length, equals(2));
  });

  test('node.queryAll', () {
    List<Element> list = div.queryAll('*');
    expect(list.length, equals(5));
    expect(list[0], isDivElement);
    expect(list[1], isCanvasElement);
    expect(list[2], isDivElement);
    expect(list[3], isDivElement);
    expect(list[4], isCanvasElement);
  });

  test('immutable', () {
    List<Element> list = div.queryAll('*');
    int len = list.length;
    expect(() {
      list.add(new DivElement());
    }, throwsUnsupportedError);
    expect(list.length, equals(len));
  });
}
