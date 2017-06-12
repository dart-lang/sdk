// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  void initPage() {
    var level1 = new UListElement()
      ..classes.add('level-1')
      ..children.add(new LIElement()..innerHtml = 'I');
    var itemii = new LIElement()
      ..classes.add('item-ii')
      ..style.position = 'relative'
      ..style.top = '4px'
      ..innerHtml = 'II';
    level1.children.add(itemii);
    var level2 = new UListElement();
    itemii.children.add(level2);
    var itema = new LIElement()
      ..classes.add('item-a')
      ..innerHtml = 'A';
    var item1 = new LIElement()
      ..classes.add('item-1')
      ..innerHtml = '1';
    var item2 = new LIElement()
      ..classes.add('item-2')
      ..innerHtml = '2';
    var level3 = new UListElement()..children.addAll([item1, item2]);
    var itemb = new LIElement()
      ..classes.add('item-b')
      ..style.position = 'relative'
      ..style.top = '20px'
      ..style.left = '150px'
      ..innerHtml = 'B'
      ..children.add(level3);
    level2.children.addAll([itema, itemb, new LIElement()..innerHtml = 'C']);
    document.body.append(level1);
    document.body.style.whiteSpace = 'nowrap';

    var bar = new DivElement()..classes.add('bar');
    var style = bar.style;
    style
      ..position = 'absolute'
      ..top = '8px'
      ..left = '90px';
    var baz = new DivElement()..classes.add('baz');
    style = baz.style;
    style
      ..position = 'absolute'
      ..top = '600px'
      ..left = '7000px';
    bar.children.add(baz);

    var quux = new DivElement()..classes.add('quux');
    var qux = new DivElement()..classes.add('qux')..children.add(quux);

    document.body.append(bar);
    document.body.append(qux);
  }

  group('offset', () {
    setUp(initPage);

    test('offsetTo', () {
      var itema = query('.item-a');
      var itemb = query('.item-b');
      var item1 = query('.item-1');
      var itemii = query('.item-ii');
      var level1 = query('.level-1');
      var baz = query('.baz');
      var bar = query('.bar');
      var qux = query('.qux');
      var quux = query('.quux');

      var point = itema.offsetTo(itemii);
      expect(point.x, 40);
      expect(point.y, inInclusiveRange(16, 20));

      expect(baz.offsetTo(bar).x, 7000);
      expect(baz.offsetTo(bar).y, inInclusiveRange(599, 604));

      qux.style.position = 'fixed';
      expect(quux.offsetTo(qux).x, 0);
      expect(quux.offsetTo(qux).y, 0);

      point = item1.offsetTo(itemb);
      expect(point.x, 40);
      expect(point.y, inInclusiveRange(16, 20));
      point = itemb.offsetTo(itemii);
      expect(point.x, 190);
      expect(point.y, inInclusiveRange(52, 60));
      point = item1.offsetTo(itemii);
      expect(point.x, 230);
      expect(point.y, inInclusiveRange(68, 80));
    });

    test('documentOffset', () {
      var bar = query('.bar');
      var baz = query('.baz');
      var qux = query('.qux');
      var quux = query('.quux');
      var itema = query('.item-a');
      var itemb = query('.item-b');
      var item1 = query('.item-1');
      var itemii = query('.item-ii');

      expect(itema.documentOffset.x, 88);
      expect(itema.documentOffset.y, inInclusiveRange(111, 160));

      expect(itemii.documentOffset.x, 48);
      expect(itemii.documentOffset.y, inInclusiveRange(95, 145));

      expect(itemb.documentOffset.x, 238);
      expect(itemb.documentOffset.y, inInclusiveRange(147, 205));

      expect(item1.documentOffset.x, 278);
      expect(item1.documentOffset.y, inInclusiveRange(163, 222));

      expect(bar.documentOffset.x, 90);
      expect(bar.documentOffset.y, 8);

      expect(baz.documentOffset.x, 7090);
      expect(baz.documentOffset.y, 608);

      expect(qux.documentOffset.x, 8);
      expect(qux.documentOffset.y, inInclusiveRange(203, 240));

      expect(quux.documentOffset.x, 8);
      expect(quux.documentOffset.y, inInclusiveRange(203, 240));
    });
  });
}
