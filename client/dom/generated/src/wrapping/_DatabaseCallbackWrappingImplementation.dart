// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DatabaseCallbackWrappingImplementation extends DOMWrapperBase implements DatabaseCallback {
  _DatabaseCallbackWrappingImplementation() : super() {}

  static create__DatabaseCallbackWrappingImplementation() native {
    return new _DatabaseCallbackWrappingImplementation();
  }

  bool handleEvent(var database) {
    if (database is Database) {
      return _handleEvent(this, database);
    } else {
      if (database is DatabaseSync) {
        return _handleEvent_2(this, database);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static bool _handleEvent(receiver, database) native;
  static bool _handleEvent_2(receiver, database) native;

  String get typeName() { return "DatabaseCallback"; }
}
