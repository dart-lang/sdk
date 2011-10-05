// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _InjectedScriptHostWrappingImplementation extends DOMWrapperBase implements InjectedScriptHost {
  _InjectedScriptHostWrappingImplementation() : super() {}

  static create__InjectedScriptHostWrappingImplementation() native {
    return new _InjectedScriptHostWrappingImplementation();
  }

  void clearConsoleMessages() {
    _clearConsoleMessages(this);
    return;
  }
  static void _clearConsoleMessages(receiver) native;

  void copyText(String text) {
    _copyText(this, text);
    return;
  }
  static void _copyText(receiver, text) native;

  int databaseId(Object database) {
    return _databaseId(this, database);
  }
  static int _databaseId(receiver, database) native;

  Object evaluate(String text) {
    return _evaluate(this, text);
  }
  static Object _evaluate(receiver, text) native;

  void inspect(Object objectId, Object hints) {
    _inspect(this, objectId, hints);
    return;
  }
  static void _inspect(receiver, objectId, hints) native;

  Object inspectedNode(int num) {
    return _inspectedNode(this, num);
  }
  static Object _inspectedNode(receiver, num) native;

  Object internalConstructorName(Object object) {
    return _internalConstructorName(this, object);
  }
  static Object _internalConstructorName(receiver, object) native;

  bool isHTMLAllCollection(Object object) {
    return _isHTMLAllCollection(this, object);
  }
  static bool _isHTMLAllCollection(receiver, object) native;

  int storageId(Object storage) {
    return _storageId(this, storage);
  }
  static int _storageId(receiver, storage) native;

  String type(Object object) {
    return _type(this, object);
  }
  static String _type(receiver, object) native;

  String get typeName() { return "InjectedScriptHost"; }
}
