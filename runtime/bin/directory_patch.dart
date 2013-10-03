// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _Directory {
  /* patch */ static _current() native "Directory_Current";
  /* patch */ static _setCurrent(path) native "Directory_SetCurrent";
  /* patch */ static _createTemp(String template, bool system)
      native "Directory_CreateTemp";
  /* patch */ static int _exists(String path) native "Directory_Exists";
  /* patch */ static _create(String path) native "Directory_Create";
  /* patch */ static _deleteNative(String path, bool recursive)
      native "Directory_Delete";
  /* patch */ static _rename(String path, String newPath)
      native "Directory_Rename";
  /* patch */ static List _list(String path, bool recursive, bool followLinks)
      native "Directory_List";
}
