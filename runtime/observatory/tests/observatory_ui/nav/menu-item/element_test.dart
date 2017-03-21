// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

main() {
  NavMenuItemElement.tag.ensureRegistration();

  group('instantiation', () {
    final label = 'custom-label';
    final link = 'link-to-target';
    test('label', () {
      final e = new NavMenuItemElement(label);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.label, equals(label), reason: 'element correctly created');
    });
    test('label', () {
      final e = new NavMenuItemElement(label, link: link);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.link, equals(link), reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created', () async {
      final label = 'custom-label';
      final e = new NavMenuItemElement(label);
      e.content = [document.createElement('content')];
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelector('content'), isNotNull,
                                                 reason: 'has content elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to label change', () async {
      final label1 = 'custom-label-1';
      final label2 = 'custom-label-2';
      final e = new NavMenuItemElement(label1);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(label1), isTrue);
      expect(e.innerHtml.contains(label2), isFalse);
      e.label = label2;
      await e.onRendered.first;
      expect(e.innerHtml.contains(label1), isFalse);
      expect(e.innerHtml.contains(label2), isTrue);
      e.remove();
      await e.onRendered.first;
    });
    test('react to link change', () async {
      final label = 'custom-label';
      final link1 = 'custom-label-1';
      final link2 = 'custom-label-2';
      final e = new NavMenuItemElement(label, link: link1);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(link1), isTrue);
      expect(e.innerHtml.contains(link2), isFalse);
      e.link = link2;
      await e.onRendered.first;
      expect(e.innerHtml.contains(link1), isFalse);
      expect(e.innerHtml.contains(link2), isTrue);
      e.remove();
      await e.onRendered.first;
    });
  });
}
