// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/general_error.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import '../mocks.dart';

main() {
  GeneralErrorElement.tag.ensureRegistration();

  final nTag = NavNotifyElement.tag.name;
  final notifications = new NotificationRepositoryMock();
  final String message = 'content-of-the-message';

  group('instantiation', () {
    test('default', () {
      final GeneralErrorElement e = new GeneralErrorElement(notifications);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.message, isNotNull, reason: 'message should not be null');
      expect(e.message, equals(''), reason: 'message should be empty');
    });
    test('message', () {
      final GeneralErrorElement e = new GeneralErrorElement(notifications,
          message: message);
      expect(e, isNotNull, reason: 'element correctly created');
      expect(e.message, isNotNull, reason: 'message should not be null');
      expect(e.message, equals(message), reason: 'message should be the same');
    });
  });
  group('elements', () {
    test('created after attachment', () async {
      final GeneralErrorElement e = new GeneralErrorElement(notifications);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.querySelectorAll(nTag).length, equals(1));
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('react to message change', () async {
      final GeneralErrorElement e = new GeneralErrorElement(notifications);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.innerHtml.contains(message), isFalse,
          reason: 'should not contain');
      e.message = message;
      await e.onRendered.first;
      expect(e.innerHtml.contains(message), isTrue,
          reason: 'should contain');
      e.message = '';
      await e.onRendered.first;
      expect(e.innerHtml.contains(message), isFalse,
          reason: 'should not contain');
      e.remove();
      await e.onRendered.first;
    });
  });
}
