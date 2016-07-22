// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class IsolateUpdateEventMock implements M.IsolateUpdateEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const IsolateUpdateEventMock({this.timestamp, this.isolate});
}
