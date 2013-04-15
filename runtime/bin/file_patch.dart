// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _FileUtils {
  /* patch */ static SendPort _newServicePort() native "File_NewServicePort";
}

patch class _File {
  /* patch */ static _exists(String path) native "File_Exists";
  /* patch */ static _create(String path) native "File_Create";
  /* patch */ static _createLink(String path, String target)
      native "File_CreateLink";
  /* patch */ static _linkTarget(String path) native "File_LinkTarget";
  /* patch */ static _delete(String path) native "File_Delete";
  /* patch */ static _deleteLink(String path) native "File_DeleteLink";
  /* patch */ static _directory(String path) native "File_Directory";
  /* patch */ static _lengthFromPath(String path) native "File_LengthFromPath";
  /* patch */ static _lastModified(String path) native "File_LastModified";
  /* patch */ static _open(String path, int mode) native "File_Open";
  /* patch */ static int _openStdio(int fd) native "File_OpenStdio";
  /* patch */ static _fullPath(String path) native "File_FullPath";
}

patch class _RandomAccessFile {
  /* patch */ static int _close(int id) native "File_Close";
  /* patch */ static _readByte(int id) native "File_ReadByte";
  /* patch */ static _read(int id, int bytes) native "File_Read";
  /* patch */ static _readInto(int id, List<int> buffer, int start, int end)
      native "File_ReadInto";
  /* patch */ static _writeByte(int id, int value) native "File_WriteByte";
  /* patch */ static _writeFrom(int id, List<int> buffer, int start, int end)
      native "File_WriteFrom";
  /* patch */ static _position(int id) native "File_Position";
  /* patch */ static _setPosition(int id, int position)
      native "File_SetPosition";
  /* patch */ static _truncate(int id, int length) native "File_Truncate";
  /* patch */ static _length(int id) native "File_Length";
  /* patch */ static _flush(int id) native "File_Flush";
}

Uint8List _makeUint8ListView(Uint8List source, int offsetInBytes, int length) {
  return new Uint8List.view(source.buffer, offsetInBytes, length);
}
