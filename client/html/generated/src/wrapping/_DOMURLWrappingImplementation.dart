// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMURLWrappingImplementation extends DOMWrapperBase implements DOMURL {
  DOMURLWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String createObjectURL(Blob blob) {
    return _ptr.createObjectURL(LevelDom.unwrap(blob));
  }

  void revokeObjectURL(String url) {
    _ptr.revokeObjectURL(url);
    return;
  }

  String get typeName() { return "DOMURL"; }
}
