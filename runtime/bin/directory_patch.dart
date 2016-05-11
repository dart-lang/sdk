// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _Directory {
  /* patch */ static _current() native "Directory_Current";
  /* patch */ static _setCurrent(path) native "Directory_SetCurrent";
  /* patch */ static _createTemp(String path) native "Directory_CreateTemp";
  /* patch */ static String _systemTemp() native "Directory_SystemTemp";
  /* patch */ static _exists(String path) native "Directory_Exists";
  /* patch */ static _create(String path) native "Directory_Create";
  /* patch */ static _deleteNative(String path, bool recursive)
      native "Directory_Delete";
  /* patch */ static _rename(String path, String newPath)
      native "Directory_Rename";
  /* patch */ static List _list(String path, bool recursive, bool followLinks)
      native "Directory_List";
}

patch class _AsyncDirectoryListerOps {
  /* patch */ factory _AsyncDirectoryListerOps(int pointer) =>
      new _AsyncDirectoryListerOpsImpl(pointer);
}

class _AsyncDirectoryListerOpsImpl extends NativeFieldWrapperClass1
                                   implements _AsyncDirectoryListerOps {
  _AsyncDirectoryListerOpsImpl._();

  factory _AsyncDirectoryListerOpsImpl(int pointer)
      => new _AsyncDirectoryListerOpsImpl._().._setPointer(pointer);

  void _setPointer(int pointer)
      native "Directory_SetAsyncDirectoryListerPointer";
  int getPointer()
      native "Directory_GetAsyncDirectoryListerPointer";
}
