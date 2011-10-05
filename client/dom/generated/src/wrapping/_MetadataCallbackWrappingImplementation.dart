// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MetadataCallbackWrappingImplementation extends DOMWrapperBase implements MetadataCallback {
  _MetadataCallbackWrappingImplementation() : super() {}

  static create__MetadataCallbackWrappingImplementation() native {
    return new _MetadataCallbackWrappingImplementation();
  }

  bool handleEvent(Metadata metadata) {
    return _handleEvent(this, metadata);
  }
  static bool _handleEvent(receiver, metadata) native;

  String get typeName() { return "MetadataCallback"; }
}
