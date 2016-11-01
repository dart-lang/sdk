// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/sentinel_value.dart';
import '../mocks.dart';

main() {
  SentinelValueElement.tag.ensureRegistration();

  const sentinel = const SentinelMock();
  test('instantiation', () {
    final e = new SentinelValueElement(sentinel);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.sentinel, equals(sentinel));
  });
  test('elements created after attachment', () async {
    final e = new SentinelValueElement(sentinel);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.text, isNotEmpty, reason: 'has text');
    expect(e.title, isNotEmpty, reason: 'has title');
    e.remove();
    await e.onRendered.first;
  });
}
