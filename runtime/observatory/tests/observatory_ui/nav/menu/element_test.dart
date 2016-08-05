// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/menu.dart';

main() {
  NavMenuElement.tag.ensureRegistration();

  group('instantiation', () {
    final label = 'custom-label';
    test('label', () {
      final e = new NavMenuElement(label);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.label, equals(label), reason: 'element correctly created');
    });
    test('not last', () {
      final e = new NavMenuElement(label, last: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.last, isFalse, reason: 'element correctly created');
    });
    test('last', () {
      final e = new NavMenuElement(label, last: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.last, isTrue, reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created', () async {
      final label = 'custom-label';
      final e = new NavMenuElement(label);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.shadowRoot.children.length, isNonZero, reason: 'has elements');
      expect(e.shadowRoot.querySelector('content'), isNotNull,
                                                 reason: 'has content elements');
      e.remove();
      await e.onRendered.first;
      expect(e.shadowRoot.children.length, isZero, reason: 'is empty');
    });
    test('react to label change', () async {
      final label1 = 'custom-label-1';
      final label2 = 'custom-label-2';
      final e = new NavMenuElement(label1);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.shadowRoot.innerHtml.contains(label1), isTrue);
      expect(e.shadowRoot.innerHtml.contains(label2), isFalse);
      e.label = label2;
      await e.onRendered.first;
      expect(e.shadowRoot.innerHtml.contains(label1), isFalse);
      expect(e.shadowRoot.innerHtml.contains(label2), isTrue);
      e.remove();
      await e.onRendered.first;
    });
    test('react to last change', () async {
      final label = 'custom-label';
      final e = new NavMenuElement(label, last: false);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.shadowRoot.innerHtml.contains('&gt;'), isTrue);
      e.last = true;
      await e.onRendered.first;
      expect(e.shadowRoot.innerHtml.contains('&gt;'), isFalse);
      e.last = false;
      await e.onRendered.first;
      expect(e.shadowRoot.innerHtml.contains('&gt;'), isTrue);
      e.remove();
      await e.onRendered.first;
    });
  });
}
