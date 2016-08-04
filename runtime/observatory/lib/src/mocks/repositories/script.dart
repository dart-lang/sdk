// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ScriptRepositoryMock implements M.ScriptRepository {
  final Map<String, M.Script> scripts;

  bool _invoked = false;
  bool get invoked => _invoked;

  ScriptRepositoryMock(this.scripts);

  Future<M.Script> get(String id) async {
    _invoked = true;
    return scripts[id];
  }
}
