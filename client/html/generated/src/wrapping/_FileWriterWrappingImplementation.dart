// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  FileWriterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get length() { return _ptr.length; }

  int get position() { return _ptr.position; }

  int get readyState() { return _ptr.readyState; }

  void abort() {
    _ptr.abort();
    return;
  }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
