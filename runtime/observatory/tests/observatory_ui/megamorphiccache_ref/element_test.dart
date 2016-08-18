// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/megamorphiccache_ref.dart';
import '../mocks.dart';

main() {
  MegamorphicCacheRefElement.tag.ensureRegistration();

  const isolate = const IsolateRefMock();
  const cache = const MegamorphicCacheRefMock();
  test('instantiation', () {
    final e = new MegamorphicCacheRefElement(isolate, cache);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.cache, equals(cache));
  });
  test('elements created after attachment', () async {
    final e = new MegamorphicCacheRefElement(isolate, cache);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
