// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitMutationObserverWrappingImplementation extends DOMWrapperBase implements WebKitMutationObserver {
  _WebKitMutationObserverWrappingImplementation() : super() {}

  static create__WebKitMutationObserverWrappingImplementation() native {
    return new _WebKitMutationObserverWrappingImplementation();
  }

  void disconnect() {
    _disconnect(this);
    return;
  }
  static void _disconnect(receiver) native;

  String get typeName() { return "WebKitMutationObserver"; }
}
