// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class IsolateRefMock implements M.IsolateRef {
  final String id;
  final int number;
  final String name;

  const IsolateRefMock({this.id, this.number, this.name});
}

class IsolateMock implements M.Isolate {
  final String id;
  final int number;
  final String name;
  final DateTime startTime;
  final bool runnable;

  const IsolateMock({this.id, this.number, this.name, this.startTime,
      this.runnable});
  // TODO(cbernaschina) add other properties.
}
