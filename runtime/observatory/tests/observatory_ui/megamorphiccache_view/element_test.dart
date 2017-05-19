// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/megamorphiccache_view.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/object_common.dart';
import '../mocks.dart';

main() {
  MegamorphicCacheViewElement.tag.ensureRegistration();

  final cTag = ObjectCommonElement.tag.name;
  final rTag = NavRefreshElement.tag.name;

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  final cache = const MegamorphicCacheMock();
  final caches = new MegamorphicCacheRepositoryMock();
  final reachableSizes = new ReachableSizeRepositoryMock();
  final retainedSizes = new RetainedSizeRepositoryMock();
  final inbounds = new InboundReferencesRepositoryMock();
  final paths = new RetainingPathRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new MegamorphicCacheViewElement(
        vm,
        isolate,
        cache,
        events,
        notifs,
        caches,
        retainedSizes,
        reachableSizes,
        inbounds,
        paths,
        objects);
    expect(e, isNotNull, reason: 'element correctly created');
    expect(e.isolate, equals(isolate));
    expect(e.cache, equals(cache));
  });
  test('elements created after attachment', () async {
    final caches = new MegamorphicCacheRepositoryMock(
        getter: expectAsync((i, id) async {
      expect(i, equals(isolate));
      expect(id, equals(cache.id));
      return cache;
    }, count: 1));
    final e = new MegamorphicCacheViewElement(
        vm,
        isolate,
        cache,
        events,
        notifs,
        caches,
        retainedSizes,
        reachableSizes,
        inbounds,
        paths,
        objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(cTag).length, equals(1));
    (e.querySelector(rTag) as NavRefreshElement).refresh();
    await e.onRendered.first;
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
