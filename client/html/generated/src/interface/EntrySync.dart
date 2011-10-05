// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface EntrySync {

  DOMFileSystemSync get filesystem();

  String get fullPath();

  bool get isDirectory();

  bool get isFile();

  String get name();

  EntrySync copyTo(DirectoryEntrySync parent, String name);

  Metadata getMetadata();

  DirectoryEntrySync getParent();

  EntrySync moveTo(DirectoryEntrySync parent, String name);

  void remove();

  String toURL();
}
