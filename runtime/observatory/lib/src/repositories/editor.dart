// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class EditorRepository extends M.EditorRepository {
  final String editor;

  EditorRepository(this.editor) {
    assert(this.editor != null);
  }

  Future<M.Sentinel> sendObject(M.IsolateRef i, M.ObjectRef object) {
    final isolate = i as S.Isolate;
    assert(isolate != null);
    return isolate.invokeRpc(
        '_sendObjectToEditor', {'editor': editor, 'objectId': object.id});
  }
}
