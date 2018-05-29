// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/flag_list.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import '../mocks.dart';

main() {
  FlagListElement.tag.ensureRegistration();

  final nTag = NavNotifyElement.tag.name;
  const vm = const VMMock();
  final events = new EventRepositoryMock();
  final notifications = new NotificationRepositoryMock();

  group('instantiation', () {
    test('default', () {
      final e = new FlagListElement(
          vm, events, new FlagsRepositoryMock(), notifications);
      expect(e, isNotNull, reason: 'element correctly created');
    });
  });
  group('elements', () {
    test('created after attachment', () async {
      const modified = const [
        const FlagMock(name: 'f1', comment: 'c1', modified: true),
      ];
      const unmodifed = const [
        const FlagMock(name: 'f2', comment: 'c2', modified: false),
        const FlagMock(name: 'f3', comment: 'c3', modified: false),
      ];
      final flags = <M.Flag>[]..addAll(modified)..addAll(unmodifed);
      final repository = new FlagsRepositoryMock(list: flags);
      final e = new FlagListElement(vm, events, repository, notifications);
      document.body.append(e);
      expect(repository.isListInvoked, isFalse);
      await e.onRendered.first;
      expect(repository.isListInvoked, isTrue);
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(nTag).length, equals(1));
      expect(e.querySelectorAll('.flag').length, equals(flags.length));
      expect(
          e.querySelectorAll('.flag.modified').length, equals(modified.length));
      expect(e.querySelectorAll('.flag.unmodified').length,
          equals(unmodifed.length));
      expect(e.querySelectorAll('.flag').length, equals(flags.length));
      expect(e.querySelectorAll('.comment').length, equals(flags.length));
      expect(e.querySelectorAll('.name').length, equals(flags.length));
      expect(e.querySelectorAll('.value').length, equals(flags.length));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
