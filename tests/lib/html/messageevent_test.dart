// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('new MessageEvent', () {
    final event = new MessageEvent('type',
        cancelable: true,
        data: 'data',
        origin: 'origin',
        lastEventId: 'lastEventId');

    expect(event.type, equals('type'));
    expect(event.bubbles, isFalse);
    expect(event.cancelable, isTrue);
    expect(event.data, equals('data'));
    expect(event.origin, equals('origin'));
    // IE allows setting this but just ignores it.
    // expect(event.lastEventId, equals('lastEventId'));
    expect(event.source, window);
    // TODO(antonm): accessing ports is not supported yet.
  });
}
