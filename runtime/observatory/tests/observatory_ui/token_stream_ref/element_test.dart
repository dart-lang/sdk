// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/token_stream_ref.dart';
import '../mocks.dart';

main() {
  TokenStreamRefElement.tag.ensureRegistration();

  const isolate = const IsolateRefMock();
  const token = const TokenStreamRefMock();
  const token_named = const TokenStreamRefMock(name: 'name');
  test('instantiation', () {
    final e = new TokenStreamRefElement(isolate, token);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.token, equals(token));
  });
  group('elements', () {
    test('created after attachment (no name)', () async {
      final e = new TokenStreamRefElement(isolate, token);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
    test('created after attachment (name)', () async {
      final e = new TokenStreamRefElement(isolate, token_named);
      document.body.append(e);
      await e.onRendered.first;
      expect(e.children.length, isNonZero, reason: 'has elements');
      expect(e.innerHtml.contains(token_named.name), isTrue);
      e.remove();
      await e.onRendered.first;
      expect(e.children.length, isZero, reason: 'is empty');
    });
  });
}
