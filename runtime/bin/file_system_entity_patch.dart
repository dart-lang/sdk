// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class FileSystemEntity {
  /* patch */ static int _getType(String path, bool followLinks)
      native "File_GetType";
  /* patch */ static bool _identical(String path1, String path2)
      native "File_AreIdentical";
}
