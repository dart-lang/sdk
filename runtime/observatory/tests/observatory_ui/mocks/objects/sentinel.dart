// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class SentinelMock implements M.Sentinel {
  final M.SentinelKind kind;
  final String valueAsString;

  const SentinelMock({this.kind: M.SentinelKind.collected,
                  this.valueAsString: 'sentinel-value'});
}
