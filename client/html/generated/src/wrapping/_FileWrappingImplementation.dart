// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWrappingImplementation extends BlobWrappingImplementation implements File {
  FileWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get fileName() { return _ptr.fileName; }

  int get fileSize() { return _ptr.fileSize; }

  DateTime get lastModifiedDate() { return _ptr.lastModifiedDate; }

  String get name() { return _ptr.name; }

  String get typeName() { return "File"; }
}
