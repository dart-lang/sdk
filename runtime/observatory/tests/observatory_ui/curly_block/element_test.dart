// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/rendering_queue.dart';

main() {
  CurlyBlockElement.tag.ensureRegistration();

  final TimedRenderingBarrier barrier = new TimedRenderingBarrier();
  final RenderingQueue queue = new RenderingQueue.fromBarrier(barrier);
  group('instantiation', () {
    test('default', () {
      final CurlyBlockElement e = new CurlyBlockElement();
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded / not disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: false,
                                                        disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('not expanded / disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: false,
                                                        disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isTrue);
    });
    test('expanded', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isFalse);
    });
    test('expanded / not disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: true,
                                                        disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isFalse);
    });
    test('expanded / disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(expanded: true,
                                                        disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isTrue);
      expect(e.disabled, isTrue);
    });
    test('not disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(disabled: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isFalse);
    });
    test('disabled', () {
      final CurlyBlockElement e = new CurlyBlockElement(disabled: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.expanded, isFalse);
      expect(e.disabled, isTrue);
    });
  });
  test('elements created', () async {
    final CurlyBlockElement e = new CurlyBlockElement(queue: queue);
    expect(e.shadowRoot, isNotNull, reason: 'shadowRoot is created');
    document.body.append(e);
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isNonZero,
      reason: 'shadowRoot has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.shadowRoot.children.length, isZero, reason: 'shadowRoot is empty');
  });
  group('content', () {
    CurlyBlockElement e;
    setUp(() async {
      e = new CurlyBlockElement(queue: queue);
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() async {
      e.remove();
      await e.onRendered.first;
    });
    test('toggles visibility', () async {
      expect(e.shadowRoot.querySelector('content'), isNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNotNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNull);
    });
    test('toggles visibility (manually)', () async {
      expect(e.shadowRoot.querySelector('content'), isNull);
      e.expanded = true;
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNotNull);
      e.expanded = false;
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNull);
    });
    test('does not toggle if disabled', () async {
      e.disabled = true;
      await e.onRendered.first;
      expect(e.expanded, isFalse);
      expect(e.shadowRoot.querySelector('content'), isNull);
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isFalse);
      expect(e.shadowRoot.querySelector('content'), isNull);
      e.disabled = false;
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isTrue);
      expect(e.shadowRoot.querySelector('content'), isNotNull);
      e.disabled = true;
      e.toggle();
      await e.onRendered.first;
      expect(e.expanded, isTrue);
      expect(e.shadowRoot.querySelector('content'), isNotNull);
    });
    test('toggles visibility (manually) if disabled', () async {
      e.disabled = true;
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNull);
      e.expanded = true;
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNotNull);
      e.expanded = false;
      await e.onRendered.first;
      expect(e.shadowRoot.querySelector('content'), isNull);
    });
  });
  group('event', () {
    CurlyBlockElement e;
    setUp(() async {
      e = new CurlyBlockElement(queue: queue);
      document.body.append(e);
      await e.onRendered.first;
    });
    tearDown(() async {
      e.remove();
      await e.onRendered.first;
    });
    test('fires on toggle', () async {
      e.onToggle.listen(expectAsync((CurlyBlockToggleEvent event){
        expect(event, isNotNull);
        expect(event.control, equals(e));
      }, count: 1));
      e.toggle();
      await e.onRendered.first;
    });
    test('fires on manual toggle', () async {
      e.onToggle.listen(expectAsync((CurlyBlockToggleEvent event){
        expect(event, isNotNull);
        expect(event.control, equals(e));
      }, count: 1));
      e.expanded = !e.expanded;
      await e.onRendered.first;
    });
    test('does not fire if setting same expanded value', () async {
      e.onToggle.listen(expectAsync((_){}, count: 0));
      e.expanded = e.expanded;
      await e.onRendered.first;
    });
  });
}
