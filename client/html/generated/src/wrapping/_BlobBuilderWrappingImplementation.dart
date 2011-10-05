// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobBuilderWrappingImplementation extends DOMWrapperBase implements BlobBuilder {
  BlobBuilderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(var blob_OR_value, String endings) {
    if (blob_OR_value is String) {
      _ptr.append(LevelDom.unwrap(blob_OR_value), endings);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  Blob getBlob(String contentType) {
    return LevelDom.wrapBlob(_ptr.getBlob(contentType));
  }

  String get typeName() { return "BlobBuilder"; }
}
