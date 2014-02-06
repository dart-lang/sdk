// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class FileStat {
  /* patch */ static _statSync(String path) native "File_Stat";
}


patch class FileSystemEntity {
  /* patch */ static _getType(String path, bool followLinks)
      native "File_GetType";
  /* patch */ static _identical(String path1, String path2)
      native "File_AreIdentical";
  /* patch */ static _resolveSymbolicLinks(String path)
      native "File_ResolveSymbolicLinks";
}
