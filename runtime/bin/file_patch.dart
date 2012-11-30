// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _FileUtils {
  /* patch */ static SendPort _newServicePort() native "File_NewServicePort";
}

patch class _File {
  /* patch */ static _exists(String name) native "File_Exists";
  /* patch */ static _create(String name) native "File_Create";
  /* patch */ static _delete(String name) native "File_Delete";
  /* patch */ static _directory(String name) native "File_Directory";
  /* patch */ static _lengthFromName(String name) native "File_LengthFromName";
  /* patch */ static _lastModified(String name) native "File_LastModified";
  /* patch */ static _open(String name, int mode) native "File_Open";
  /* patch */ static int _openStdio(int fd) native "File_OpenStdio";
  /* patch */ static _fullPath(String name) native "File_FullPath";
}

patch class _RandomAccessFile {
  /* patch */ static int _close(int id) native "File_Close";
  /* patch */ static _readByte(int id) native "File_ReadByte";
  /* patch */ static _read(int id, int bytes) native "File_Read";
  /* patch */ static _readList(int id, List<int> buffer, int offset, int bytes)
      native "File_ReadList";
  /* patch */ static _writeByte(int id, int value) native "File_WriteByte";
  /* patch */ static _writeList(int id, List<int> buffer, int offset, int bytes)
      native "File_WriteList";
  /* patch */ static _position(int id) native "File_Position";
  /* patch */ static _setPosition(int id, int position)
      native "File_SetPosition";
  /* patch */ static _truncate(int id, int length) native "File_Truncate";
  /* patch */ static _length(int id) native "File_Length";
  /* patch */ static _flush(int id) native "File_Flush";
}
