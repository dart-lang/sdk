// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFormDataWrappingImplementation extends DOMWrapperBase implements DOMFormData {
  DOMFormDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(String name, String value) {
    _ptr.append(name, value);
    return;
  }

  String get typeName() { return "DOMFormData"; }
}
