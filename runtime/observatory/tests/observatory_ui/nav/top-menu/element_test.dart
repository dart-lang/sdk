// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/helpers/rendering_queue.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';

main() {
  NavTopMenuElement.tag.ensureRegistration();

  final String tag = NavMenuElement.tag.name;

  final TimedRenderingBarrier barrier = new TimedRenderingBarrier();
  final RenderingQueue queue = new RenderingQueue.fromBarrier(barrier);
  group('instantiation', () {
    test('default', () {
      final NavTopMenuElement e = new NavTopMenuElement();
      expect(e, isNotNull, reason: 'element correctly created');
    });
    test('not last', () {
      final NavTopMenuElement e = new NavTopMenuElement(last: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.last, isFalse, reason: 'element correctly created');
    });
    test('last', () {
      final NavTopMenuElement e = new NavTopMenuElement(last: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.last, isTrue, reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created', () async {
      final NavTopMenuElement e = new NavTopMenuElement(queue: queue);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.shadowRoot.children.length, isNonZero, reason: 'has elements');
      expect(e.shadowRoot.querySelector('content'), isNotNull,
                                                 reason: 'has content elements');
      e.remove();
      await e.onRendered.first;
      expect(e.shadowRoot.children.length, isZero, reason: 'is empty');
    });
    test('react to last change', () async {
      final NavTopMenuElement e = new NavTopMenuElement(last: false,
          queue: queue);
      document.body.append(e);
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement).last, isFalse);
      e.last = true;
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement).last, isTrue);
      e.last = false;
      await e.onRendered.first;
      expect((e.shadowRoot.querySelector(tag) as NavMenuElement).last, isFalse);
      e.remove();
      await e.onRendered.first;
    });
  });
}
