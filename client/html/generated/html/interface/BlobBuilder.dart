// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BlobBuilder default _BlobBuilderFactoryProvider {

  BlobBuilder();

  void append(var arrayBuffer_OR_blob_OR_value, [String endings]);

  Blob getBlob([String contentType]);
}
