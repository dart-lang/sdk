// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class EvalRepository extends M.EvalRepository {
  Future<M.ObjectRef> evaluate(M.IsolateRef i, M.ObjectRef o, String e,
      {bool disableBreakpoints: false}) async {
    S.Isolate isolate = i as S.Isolate;
    S.ServiceObject object = o as S.HeapObject;
    assert(isolate != null);
    assert(object != null);
    assert(e != null);
    return await isolate.eval(object, e,
        disableBreakpoints: disableBreakpoints);
  }
}
