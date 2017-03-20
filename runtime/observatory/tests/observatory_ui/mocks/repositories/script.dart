// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Script>
    ScriptRepositoryMockCallback(M.IsolateRef isolate, String id);

class ScriptRepositoryMock implements M.ScriptRepository {
  final ScriptRepositoryMockCallback _get;

  ScriptRepositoryMock({ScriptRepositoryMockCallback getter})
    : _get = getter;

  Future<M.Script> get(M.IsolateRef isolate, String id){
    if (_get != null) {
      return _get(isolate, id);
    }
    return new Future.value(null);
  }
}
