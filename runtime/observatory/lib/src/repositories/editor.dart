// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class EditorRepository extends M.EditorRepository {
  final S.VM _vm;
  final String _editor;

  bool get canOpenClass => _getService() != null;

  EditorRepository(S.VM vm, {String editor})
      : _vm = vm,
        _editor = editor {
    assert(_vm != null);
  }

  S.Service _getService() {
    if (_vm.services.isEmpty) {
      return null;
    }
    if (_editor == null) {
      return _vm.services.where((s) => s.service == 'openSourceLocation').first;
    }
    return _vm.services
        .where((s) => s.service == 'openSourceLocation' && s.alias == _editor)
        .single;
  }

  Future openClass(M.IsolateRef i, M.ClassRef c) async {
    S.Class clazz = c as S.Class;
    assert(clazz != null);
    if (!clazz.loaded) {
      await clazz.load();
    }
    if (clazz.location == null) {
      return new Future.value();
    }
    return await openSourceLocation(i, clazz.location);
  }

  Future openSourceLocation(M.IsolateRef i, M.SourceLocation l) async {
    final isolate = i as S.Isolate;
    assert(isolate != null);
    assert(l != null);
    return await isolate.invokeRpc(_getService().method,
        {'scriptId': l.script.id, 'tokenPos': l.tokenPos});
  }
}
