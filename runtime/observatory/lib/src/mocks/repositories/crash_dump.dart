// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef void CrashDumpRepositoryMockCallback(Map);

class CrashDumpRepositoryMock implements M.CrashDumpRepository {
  final CrashDumpRepositoryMockCallback _load;

  bool loadInvoked = false;

  void load(Map dump) {
    loadInvoked = true;
    if (_load != null) {
      _load(dump);
    }
  }

  CrashDumpRepositoryMock({CrashDumpRepositoryMockCallback load})
    : _load = load;
}
