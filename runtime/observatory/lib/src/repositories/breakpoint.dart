// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class BreakpointRepository extends M.BreakpointRepository {
  Future addOnActivation(M.IsolateRef i, M.Instance closure) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    await isolate.addBreakOnActivation(closure);
  }

  Future remove(M.IsolateRef i, M.Breakpoint breakpoint) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    await isolate.removeBreakpoint(breakpoint);
  }
}
