// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "common_patch.dart";

@patch
class FileStat {
  @patch
  static _statSync(_Namespace namespace, String path) native "File_Stat";
}

@patch
class FileSystemEntity {
  @patch
  static _getTypeNative(_Namespace namespace, String path, bool followLinks)
      native "File_GetType";
  @patch
  static _identicalNative(_Namespace namespace, String path1, String path2)
      native "File_AreIdentical";
  @patch
  static _resolveSymbolicLinks(_Namespace namespace, String path)
      native "File_ResolveSymbolicLinks";
}
