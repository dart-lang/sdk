// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/heap_snapshot.dart';
import '../mocks.dart';

main() {
  HeapSnapshotElement.tag.ensureRegistration();

  final tTag = VirtualTreeElement.tag.name;

  const vm = const VMMock();
  const isolate = const IsolateRefMock();
  final events = new EventRepositoryMock();
  final notifs = new NotificationRepositoryMock();
  final snapshots = new HeapSnapshotRepositoryMock();
  final objects = new ObjectRepositoryMock();
  test('instantiation', () {
    final e = new HeapSnapshotElement(
        vm, isolate, events, notifs, snapshots, objects);
    expect(e, isNotNull, reason: 'element correctly created');
  });
  test('elements created', () async {
    final controller =
        new StreamController<M.HeapSnapshotLoadingProgressEvent>.broadcast();
    final snapshots =
        new HeapSnapshotRepositoryMock(getter: (M.IsolateRef i, bool gc) {
      expect(i, equals(isolate));
      expect(gc, isFalse);
      return controller.stream;
    });
    final e = new HeapSnapshotElement(
        vm, isolate, events, notifs, snapshots, objects);
    document.body.append(e);
    await e.onRendered.first;
    expect(e.children.length, isNonZero, reason: 'has elements');
    expect(e.querySelectorAll(tTag).length, isZero);
    controller.add(const HeapSnapshotLoadingProgressEventMock(
        progress: const HeapSnapshotLoadingProgressMock(
            status: M.HeapSnapshotLoadingStatus.fetching)));
    await e.onRendered.first;
    expect(e.querySelectorAll(tTag).length, isZero);
    controller.add(const HeapSnapshotLoadingProgressEventMock(
        progress: const HeapSnapshotLoadingProgressMock(
            status: M.HeapSnapshotLoadingStatus.loading)));
    controller.add(new HeapSnapshotLoadingProgressEventMock(
        progress: new HeapSnapshotLoadingProgressMock(
            status: M.HeapSnapshotLoadingStatus.loaded,
            snapshot: new HeapSnapshotMock(timestamp: new DateTime.now()))));
    controller.close();
    await e.onRendered.first;
    expect(e.querySelectorAll(tTag).length, equals(1));
    e.remove();
    await e.onRendered.first;
    expect(e.children.length, isZero, reason: 'is empty');
  });
}
