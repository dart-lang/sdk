// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/refresh.dart';

main() {
  NavRefreshElement.tag.ensureRegistration();

  group('instantiation', () {
    test('no parameters', () {
      final e = new NavRefreshElement();
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.label, isNotNull, reason: 'label is set to default');
      expect(e.disabled, isFalse, reason: 'element correctly created');
    });
    test('label', () {
      final label = 'custom-label';
      final e = new NavRefreshElement(label: label);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.label, isNotNull, reason: 'label is set');
      expect(e.label, equals(label), reason: 'label is set to value');
    });
    test('not disabled', () {
      final e = new NavRefreshElement(disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.disabled, isFalse, reason: 'element correctly created');
    });
    test('disabled', () {
      final e = new NavRefreshElement(disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.disabled, isTrue, reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created after attachment', () async {
      final e = new NavRefreshElement();
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('contain custom label', () async {
      final label = 'custom-label';
      final e = new NavRefreshElement(label: label);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(label), isTrue);
      e.remove();
      await e.onRendered.first;
    });
    test('react to label change', () async {
      final label1 = 'custom-label-1';
      final label2 = 'custom-label-2';
      final e = new NavRefreshElement(label: label1);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(label1), isTrue);
      expect(e.innerHtml.contains(label2), isFalse);
      e.label = label2;
      await e.onRendered.first;
      expect(e.innerHtml.contains(label2), isTrue);
      expect(e.innerHtml.contains(label1), isFalse);
      e.remove();
      await e.onRendered.first;
    });
    test('react to disabled change', () async {
      final e = new NavRefreshElement(disabled: false);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.disabled, isFalse);
      e.disabled = true;
      await e.onRendered.first;
      expect(e.disabled, isTrue);
      e.remove();
      await e.onRendered.first;
    });
  });
  group('event', () {
    NavRefreshElement e;
    StreamSubscription sub;
    setUp(() async {
      e = new NavRefreshElement();
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() async {
      sub.cancel();
      e.remove();
      await e.onRendered.first;
    });
    test('fires', () async {
      sub = e.onRefresh.listen(expectAsync((event) {
        expect(event, isNotNull, reason: 'event passed');
        expect(event is RefreshEvent, isTrue, reason: 'is the right event');
        expect(event.element, equals(e), reason: 'is related to the element');
      }, count: 1));
      e.refresh();
    });
    test('fires on click', () async {
      sub = e.onRefresh.listen(expectAsync((event) {
        expect(event, isNotNull, reason: 'event passed');
        expect(event is RefreshEvent, isTrue, reason: 'is the right event');
        expect(event.element, equals(e), reason: 'is related to the element');
      }, count: 1));
      e.querySelector('button').click();
    });
    test('does not fire if disabled', () async {
      e.disabled = true;
      sub = e.onRefresh.listen(expectAsync((_) {}, count: 0));
      e.refresh();
    });
    test('does not fires on click if disabled', () async {
      e.disabled = true;
      sub = e.onRefresh.listen(expectAsync((_) {}, count: 0));
      e.querySelector('button').click();
    });
  });
}
