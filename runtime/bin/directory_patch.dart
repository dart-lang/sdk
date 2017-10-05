// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class _Directory {
  @patch
  static _current(_Namespace namespace) native "Directory_Current";
  @patch
  static _setCurrent(_Namespace namespace, path) native "Directory_SetCurrent";
  @patch
  static _createTemp(_Namespace namespace, String path)
      native "Directory_CreateTemp";
  @patch
  static String _systemTemp(_Namespace namespace) native "Directory_SystemTemp";
  @patch
  static _exists(_Namespace namespace, String path) native "Directory_Exists";
  @patch
  static _create(_Namespace namespace, String path) native "Directory_Create";
  @patch
  static _deleteNative(_Namespace namespace, String path, bool recursive)
      native "Directory_Delete";
  @patch
  static _rename(_Namespace namespace, String path, String newPath)
      native "Directory_Rename";
  @patch
  static void _fillWithDirectoryListing(
      _Namespace namespace,
      List<FileSystemEntity> list,
      String path,
      bool recursive,
      bool followLinks) native "Directory_FillWithDirectoryListing";
}

@patch
class _AsyncDirectoryListerOps {
  @patch
  factory _AsyncDirectoryListerOps(int pointer) =>
      new _AsyncDirectoryListerOpsImpl(pointer);
}

class _AsyncDirectoryListerOpsImpl extends NativeFieldWrapperClass1
    implements _AsyncDirectoryListerOps {
  _AsyncDirectoryListerOpsImpl._();

  factory _AsyncDirectoryListerOpsImpl(int pointer) =>
      new _AsyncDirectoryListerOpsImpl._().._setPointer(pointer);

  void _setPointer(int pointer)
      native "Directory_SetAsyncDirectoryListerPointer";
  int getPointer() native "Directory_GetAsyncDirectoryListerPointer";
}

// Corelib 'Uri.base' implementation.
// Uri.base is susceptible to changes in the current working directory.
Uri _uriBaseClosure() {
  var result = _Directory._current(_Namespace._namespace);
  if (result is OSError) {
    throw new FileSystemException(
        "Getting current working directory failed", "", result);
  }
  return new Uri.directory(result);
}

_getUriBaseClosure() => _uriBaseClosure;
