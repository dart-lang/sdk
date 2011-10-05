// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntriesCallbackWrappingImplementation extends DOMWrapperBase implements EntriesCallback {
  _EntriesCallbackWrappingImplementation() : super() {}

  static create__EntriesCallbackWrappingImplementation() native {
    return new _EntriesCallbackWrappingImplementation();
  }

  bool handleEvent(EntryArray entries) {
    return _handleEvent(this, entries);
  }
  static bool _handleEvent(receiver, entries) native;

  String get typeName() { return "EntriesCallback"; }
}
