// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DirectoryEntry extends Entry {

  DirectoryReader createReader();

  void getDirectory(String path, WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null);

  void getFile(String path, WebKitFlags flags = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null);

  void removeRecursively(VoidCallback successCallback = null, ErrorCallback errorCallback = null);
}
