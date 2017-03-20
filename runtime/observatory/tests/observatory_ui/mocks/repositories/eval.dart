// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Object> EvalRepositoryMockCallback(M.IsolateRef isolate,
                                                    M.ObjectRef context,
                                                    String expression);

class EvalRepositoryMock implements M.EvalRepository {
  final EvalRepositoryMockCallback _get;

  EvalRepositoryMock({EvalRepositoryMockCallback getter})
    : _get = getter;

  Future<M.Object> evaluate(M.IsolateRef isolate, M.ObjectRef context,
                            String expression){
    if (_get != null) {
      return _get(isolate, context, expression);
    }
    return new Future.value(null);
  }
}
