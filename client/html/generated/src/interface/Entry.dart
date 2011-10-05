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

  void copyTo(DirectoryEntry parent, String name, EntryCallback successCallback, ErrorCallback errorCallback);

  void getMetadata(MetadataCallback successCallback, ErrorCallback errorCallback);

  void getParent(EntryCallback successCallback, ErrorCallback errorCallback);

  void moveTo(DirectoryEntry parent, String name, EntryCallback successCallback, ErrorCallback errorCallback);

  void remove(VoidCallback successCallback, ErrorCallback errorCallback);

  String toURL();
}
