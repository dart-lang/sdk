// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderSyncWrappingImplementation extends DOMWrapperBase implements FileReaderSync {
  FileReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer readAsArrayBuffer(Blob blob) {
    return LevelDom.wrapArrayBuffer(_ptr.readAsArrayBuffer(LevelDom.unwrap(blob)));
  }

  String readAsBinaryString(Blob blob) {
    return _ptr.readAsBinaryString(LevelDom.unwrap(blob));
  }

  String readAsDataURL(Blob blob) {
    return _ptr.readAsDataURL(LevelDom.unwrap(blob));
  }

  String readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      return _ptr.readAsText(LevelDom.unwrap(blob));
    } else {
      return _ptr.readAsText(LevelDom.unwrap(blob), encoding);
    }
  }
}
