// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

class ScriptRepository implements M.ScriptRepository {
  final S.Isolate isolate;

  ScriptRepository(this.isolate);

  Future<M.Script> get(String id) async {
    return (await isolate.getObject(id)) as M.Script;
  }
}
