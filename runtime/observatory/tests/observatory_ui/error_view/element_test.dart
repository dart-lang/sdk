// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/error_view.dart';
import '../mocks.dart';

main() {
  ErrorViewElement.tag.ensureRegistration();

  final notifs = new NotificationRepositoryMock();
  final error = const ErrorMock();
  test('instantiation', () {
    final e = new ErrorViewElement(notifs, error);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.error, equals(error));
  });
  test('elements created after attachment', () async {
    final e = new ErrorViewElement(notifs, error);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
