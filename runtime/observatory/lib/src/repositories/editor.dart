// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class EditorRepository extends M.EditorRepository {
  final S.VM _vm;
  final String _editor;

  bool get isAvailable => _getService() != null;

  EditorRepository(S.VM vm, {String editor})
      : _vm = vm,
        _editor = editor {
    assert(_vm != null);
  }

  S.Service _getService() {
    Iterable<M.Service> services =
        _vm.services.where((s) => s.service == 'openSourceLocation');
    if (_editor != null) {
      services = services.where((s) => s.alias == _editor);
    }
    if (services.isNotEmpty) {
      return services.first;
    }
    return null;
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

  Future openField(M.IsolateRef i, M.FieldRef f) async {
    S.Field field = f as S.Field;
    assert(field != null);
    if (!field.loaded) {
      await field.load();
    }
    if (field.location == null) {
      return new Future.value();
    }
    return await openSourceLocation(i, field.location);
  }

  Future openFunction(M.IsolateRef i, M.FunctionRef f) async {
    S.ServiceFunction field = f as S.ServiceFunction;
    assert(field != null);
    if (!field.loaded) {
      await field.load();
    }
    if (field.location == null) {
      return new Future.value();
    }
    return await openSourceLocation(i, field.location);
  }

  Future openObject(M.IsolateRef i, M.ObjectRef o) async {
    assert(o != null);
    if (o is M.ClassRef) {
      return await openClass(i, o);
    }
    if (o is M.InstanceRef) {
      return await openClass(i, o.clazz);
    }
    if (o is M.FieldRef) {
      return await openField(i, o);
    }
    if (o is M.FunctionRef) {
      return await openFunction(i, o);
    }
    if (o is M.InstanceRef) {
      if (o.closureFunction != null) {
        return await openFunction(i, o.closureFunction);
      }
      return await openClass(i, o.clazz);
    }
    return new Future.value();
  }

  Future openSourceLocation(M.IsolateRef i, M.SourceLocation l) async {
    final isolate = i as S.Isolate;
    assert(isolate != null);
    assert(l != null);
    return await isolate.invokeRpc(_getService().method,
        {'scriptId': l.script.id, 'tokenPos': l.tokenPos});
  }
}
