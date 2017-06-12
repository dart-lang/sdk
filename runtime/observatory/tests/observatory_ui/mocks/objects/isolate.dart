// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class IsolateRefMock implements M.IsolateRef {
  final String id;
  final int number;
  final String name;

  const IsolateRefMock({this.id: 'i-id', this.number, this.name: 'i-name'});

  Future collectAllGarbage() async {
    throw "Unimplemented";
  }
}

class IsolateMock implements M.Isolate {
  final String id;
  final int number;
  final String name;
  final DateTime startTime;
  final bool runnable;
  final Iterable<M.LibraryRef> libraries;
  final M.Error error;
  final Iterable<String> extensionRPCs;
  final Map counters;
  final M.HeapSpace newSpace;
  final M.HeapSpace oldSpace;
  final M.IsolateStatus status;
  final M.DebugEvent pauseEvent;
  final M.LibraryRef rootLibrary;
  final M.FunctionRef entry;
  final Iterable<M.Thread> threads = null;
  final int zoneHighWatermark = 0;
  final int numZoneHandles = 0;
  final int numScopedHandles = 0;

  const IsolateMock(
      {this.id: 'i-id',
      this.number,
      this.name: 'i-name',
      this.startTime,
      this.runnable: true,
      this.libraries: const [],
      this.error,
      this.extensionRPCs: const [],
      this.counters: const {},
      this.newSpace: const HeapSpaceMock(),
      this.oldSpace: const HeapSpaceMock(),
      this.status: M.IsolateStatus.loading,
      this.pauseEvent,
      this.rootLibrary,
      this.entry});
}
