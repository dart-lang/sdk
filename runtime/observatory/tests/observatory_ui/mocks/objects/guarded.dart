// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class GuardedMock<T> implements M.Guarded<T> {
  bool get isSentinel => asSentinel != null;
  bool get isValue => asValue != null;
  final T asValue;
  final M.Sentinel asSentinel;

  const GuardedMock.fromValue(this.asValue) : asSentinel = null;

  const GuardedMock.fromSentinel(this.asSentinel) : asValue = null;
}
