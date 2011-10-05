// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SQLTransactionErrorCallbackWrappingImplementation extends DOMWrapperBase implements SQLTransactionErrorCallback {
  _SQLTransactionErrorCallbackWrappingImplementation() : super() {}

  static create__SQLTransactionErrorCallbackWrappingImplementation() native {
    return new _SQLTransactionErrorCallbackWrappingImplementation();
  }

  bool handleEvent(SQLError error) {
    return _handleEvent(this, error);
  }
  static bool _handleEvent(receiver, error) native;

  String get typeName() { return "SQLTransactionErrorCallback"; }
}
