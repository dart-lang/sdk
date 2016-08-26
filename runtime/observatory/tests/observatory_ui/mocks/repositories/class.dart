// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Class> ClassRepositoryMockObjectCallback();
typedef Future<M.Class> ClassRepositoryMockGetterCallback(String id);

class ClassRepositoryMock implements M.ClassRepository {
  final ClassRepositoryMockObjectCallback _object;
  final ClassRepositoryMockGetterCallback _get;

  ClassRepositoryMock({ClassRepositoryMockObjectCallback object,
                       ClassRepositoryMockGetterCallback getter})
    : _object = object,
      _get = getter;

  Future<M.Class> getObject(){
    if (_object != null) {
      return _object();
    }
    return new Future.value(null);
  }

  Future<M.Class> get(String id){
    if (_get != null) {
      return _get(id);
    }
    return new Future.value(null);
  }
}
