// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/curly_block.dart';

main() {
  CurlyBlockElement.tag.ensureRegistration();

  group('instantiation', () {
    test('default', () {
      final e = new CurlyBlockElement();
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded', () {
      final e = new CurlyBlockElement(expanded: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded / not disabled', () {
      final e = new CurlyBlockElement(expanded: false, disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded / disabled', () {
      final e = new CurlyBlockElement(expanded: false, disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isTrue);
    });
    test('expanded', () {
      final e = new CurlyBlockElement(expanded: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isFalse);
    });
    test('expanded / not disabled', () {
      final e = new CurlyBlockElement(expanded: true, disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isFalse);
    });
    test('expanded / disabled', () {
      final e = new CurlyBlockElement(expanded: true, disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isTrue);
    });
    test('not disabled', () {
      final e = new CurlyBlockElement(disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('disabled', () {
      final e = new CurlyBlockElement(disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isTrue);
    });
  });
  test('elements created', () async {
    final e = new CurlyBlockElement();
    expect(e.children, isEmpty, reason: 'is empty');
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children, isNotEmpty, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children, isEmpty, reason: 'is empty');
  });
  group('content', () {
    CurlyBlockElement e;
    setUp(() async {
      e = new CurlyBlockElement();
      e.content = [document.createElement('content')];
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() {
      e.remove();
    });
    test('toggles visibility', () async {
      expect(e.querySelector('content'), isNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.querySelector('content'), isNotNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.querySelector('content'), isNull);
      e.remove();
    });
    test('toggles visibility (manually)', () async {
      expect(e.querySelector('content'), isNull);
      e.expanded = true;
      await e.onRendered.first;
      expect(e.querySelector('content'), isNotNull);
      e.expanded = false;
      await e.onRendered.first;
      expect(e.querySelector('content'), isNull);
      e.remove();
    });
    test('does not toggle if disabled', () async {
      e.disabled = true;
      await e.onRendered.first;
      expect(e.expanded, isFalse);
      expect(e.querySelector('content'), isNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isFalse);
      expect(e.querySelector('content'), isNull);
      e.disabled = false;
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isTrue);
      expect(e.querySelector('content'), isNotNull);
      e.disabled = true;
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isTrue);
      expect(e.querySelector('content'), isNotNull);
      e.remove();
    });
    test('toggles visibility (manually) if disabled', () async {
      e.disabled = true;
      await e.onRendered.first;
      expect(e.querySelector('content'), isNull);
      e.expanded = true;
      await e.onRendered.first;
      expect(e.querySelector('content'), isNotNull);
      e.expanded = false;
      await e.onRendered.first;
      expect(e.querySelector('content'), isNull);
      e.remove();
    });
  });
  group('event', () {
    CurlyBlockElement e;
    setUp(() async {
      e = new CurlyBlockElement();
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() async {
      e.remove();
      await e.onRendered.first;
    });
    test('fires on toggle', () async {
      e.onToggle.listen(expectAsync((CurlyBlockToggleEvent event) {
        expect(event, isNotNull);
        expect(event.control, equals(e));
      }, count: 1));
      e.toggle();
      await e.onRendered.first;
    });
    test('fires on manual toggle', () async {
      e.onToggle.listen(expectAsync((CurlyBlockToggleEvent event) {
        expect(event, isNotNull);
        expect(event.control, equals(e));
      }, count: 1));
      e.expanded = !e.expanded;
      await e.onRendered.first;
    });
    test('does not fire if setting same expanded value', () async {
      e.onToggle.listen(expectAsync((_) {}, count: 0));
      e.expanded = e.expanded;
      await e.onRendered.first;
    });
  });
}
