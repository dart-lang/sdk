// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/sample_buffer_control.dart';
import '../mocks.dart';

main() {
  SampleBufferControlElement.tag.ensureRegistration();

  group('instantiation', () {
    SampleProfileLoadingProgressMock progress;
    StreamController<SampleProfileLoadingProgressEventMock> events;
    setUp(() {
      progress = new SampleProfileLoadingProgressMock();
      events = new StreamController<SampleProfileLoadingProgressEventMock>();
    });
    test('no additional parameters', () {
      final e = new SampleBufferControlElement(progress, events.stream);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.progress, equals(progress));
      expect(e.selectedTag, equals(M.SampleProfileTag.none));
      expect(e.showTag, isTrue);
    });
    test('selected tag', () {
      const tag = M.SampleProfileTag.userOnly;
      final e = new SampleBufferControlElement(progress, events.stream,
          selectedTag: tag);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.progress, equals(progress));
      expect(e.selectedTag, equals(tag));
      expect(e.showTag, isTrue);
    });
    test('show tag (true)', () {
      final e = new SampleBufferControlElement(progress, events.stream,
          showTag: true);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.progress, equals(progress));
      expect(e.selectedTag, equals(M.SampleProfileTag.none));
      expect(e.showTag, isTrue);
    });
    test('show tag (false)', () {
      final e = new SampleBufferControlElement(progress, events.stream,
          showTag: false);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.progress, equals(progress));
      expect(e.selectedTag, equals(M.SampleProfileTag.none));
      expect(e.showTag, isFalse);
    });
  });
  group('elements', () {
    SampleProfileLoadingProgressMock progress;
    StreamController<SampleProfileLoadingProgressEventMock> events;
    setUp(() {
      progress = new SampleProfileLoadingProgressMock();
      events = new StreamController<SampleProfileLoadingProgressEventMock>();
    });
    test('created after attachment', () async {
      final e = new SampleBufferControlElement(progress, events.stream);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('listen for status changes', () async {
      final e = new SampleBufferControlElement(progress, events.stream);
      expect(events.hasListener, isFalse);
      document.body.append(e);
      await e.onRendered.first;
      expect(events.hasListener, isTrue);
      events.add(new SampleProfileLoadingProgressEventMock(progress: progress));
      events.close();
      await e.onRendered.first;
      e.remove();
      await e.onRendered.first;
    });
    test('follow updates changes', () async {
      final e = new SampleBufferControlElement(progress, events.stream);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.fetching)));
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.loading)));
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.loaded,
              profile: new SampleProfileMock())));
      events.close();
      await e.onRendered.first;
      expect(e.querySelector('select'), isNotNull);
      e.remove();
      await e.onRendered.first;
    });
    test('follow updates changes (no tag)', () async {
      final e = new SampleBufferControlElement(progress, events.stream,
          showTag: false);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.fetching)));
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.loading)));
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.loaded,
              profile: new SampleProfileMock())));
      await e.onRendered.first;
      expect(e.querySelector('select'), isNull);
      e.remove();
      await e.onRendered.first;
    });
  });
  group('events', () {
    SampleProfileLoadingProgressMock progress;
    StreamController<SampleProfileLoadingProgressEventMock> events;
    setUp(() {
      progress = new SampleProfileLoadingProgressMock();
      events = new StreamController<SampleProfileLoadingProgressEventMock>();
    });
    test('onModeChange', () async {
      final e = new SampleBufferControlElement(progress, events.stream);
      document.body.append(e);
      await e.onRendered.first;
      events.add(new SampleProfileLoadingProgressEventMock(
          progress: new SampleProfileLoadingProgressMock(
              status: M.SampleProfileLoadingStatus.loaded,
              profile: new SampleProfileMock())));
      await e.onRendered.first;
      expect(e.selectedTag, equals(M.SampleProfileTag.none));
      e.onTagChange.listen(expectAsync((_) {
        expect(e.selectedTag, equals(M.SampleProfileTag.userOnly));
      }, count: 1));
      final select = (e.querySelector('.tag-select') as SelectElement);
      select.selectedIndex = select.options.indexOf((select.options.toSet()
            ..removeAll(select.selectedOptions))
          .toList()
          .first);
      select.dispatchEvent(new Event("change"));
      e.remove();
      await e.onRendered.first;
    });
  });
}
