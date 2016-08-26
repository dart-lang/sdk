// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class HeapSpaceMock implements M.HeapSpace {
  final int used;
  final int capacity;
  final int collections;
  final int external;
  final Duration avgCollectionTime;
  final Duration totalCollectionTime;
  final Duration avgCollectionPeriod;
  const HeapSpaceMock({this.used: 0, this.capacity: 1, this.collections: 0,
                       this.external: 1,
                       this.avgCollectionTime: const Duration(),
                       this.totalCollectionTime: const Duration(),
                       this.avgCollectionPeriod: const Duration()});
}
