// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobBuilderWrappingImplementation extends DOMWrapperBase implements BlobBuilder {
  BlobBuilderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(var blob_OR_value, [String endings = null]) {
    if (blob_OR_value is Blob) {
      if (endings === null) {
        _ptr.append(LevelDom.unwrap(blob_OR_value));
        return;
      }
    } else {
      if (blob_OR_value is String) {
        if (endings === null) {
          _ptr.append(LevelDom.unwrap(blob_OR_value));
          return;
        } else {
          _ptr.append(LevelDom.unwrap(blob_OR_value), endings);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Blob getBlob([String contentType = null]) {
    if (contentType === null) {
      return LevelDom.wrapBlob(_ptr.getBlob());
    } else {
      return LevelDom.wrapBlob(_ptr.getBlob(contentType));
    }
  }
}
