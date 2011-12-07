// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderWrappingImplementation extends DOMWrapperBase implements FileReader {
  FileReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get readyState() { return _ptr.readyState; }

  String get result() { return _ptr.result; }

  void abort() {
    _ptr.abort();
    return;
  }

  void readAsArrayBuffer(Blob blob) {
    _ptr.readAsArrayBuffer(LevelDom.unwrap(blob));
    return;
  }

  void readAsBinaryString(Blob blob) {
    _ptr.readAsBinaryString(LevelDom.unwrap(blob));
    return;
  }

  void readAsDataURL(Blob blob) {
    _ptr.readAsDataURL(LevelDom.unwrap(blob));
    return;
  }

  void readAsText(Blob blob, [String encoding]) {
    if (encoding === null) {
      _ptr.readAsText(LevelDom.unwrap(blob));
      return;
    } else {
      _ptr.readAsText(LevelDom.unwrap(blob), encoding);
      return;
    }
  }
}
