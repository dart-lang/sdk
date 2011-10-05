// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Entry {

  DOMFileSystem get filesystem();

  String get fullPath();

  bool get isDirectory();

  bool get isFile();

  String get name();

  void copyTo(DirectoryEntry parent, String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null);

  void getMetadata(MetadataCallback successCallback = null, ErrorCallback errorCallback = null);

  void getParent(EntryCallback successCallback = null, ErrorCallback errorCallback = null);

  void moveTo(DirectoryEntry parent, String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null);

  void remove(VoidCallback successCallback = null, ErrorCallback errorCallback = null);

  String toURL();
}
