// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntryCallbackWrappingImplementation extends DOMWrapperBase implements EntryCallback {
  _EntryCallbackWrappingImplementation() : super() {}

  static create__EntryCallbackWrappingImplementation() native {
    return new _EntryCallbackWrappingImplementation();
  }

  bool handleEvent(Entry entry) {
    return _handleEvent(this, entry);
  }
  static bool _handleEvent(receiver, entry) native;

  String get typeName() { return "EntryCallback"; }
}
