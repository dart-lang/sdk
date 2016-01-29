// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/constant.dart';

bool _isJsLibType(String expectedName, Element e) =>
    e?.name == expectedName && _isJsLib(e.library);

/// Returns true if [e] represents any library from `package:js` or is the
/// internal `dart:_js_helper` library.
bool _isJsLib(LibraryElement e) {
  if (e == null) return false;
  var uri = e.source.uri;
  if (uri.scheme == 'package' && uri.path.startsWith('js/')) return true;
  if (uri.scheme == 'dart') {
    return uri.path == '_js_helper' || uri.path == '_foreign_helper';
  }
  return false;
}

/// Whether [value] is a `@rest` annotation (to be used on function parameters
/// to have them compiled as `...` rest params in ES6 outputs).
bool isJsRestAnnotation(DartObjectImpl value) =>
    _isJsLibType('_Rest', value.type.element);

/// Whether [i] is a `spread` invocation (to be used on function arguments
/// to have them compiled as `...` spread args in ES6 outputs).
bool isJsSpreadInvocation(MethodInvocation i) =>
    _isJsLibType('spread', i.methodName?.bestElement);

// TODO(jmesserly): Move JsPeerInterface to package:js (see issue #135).
bool isJSAnnotation(DartObjectImpl value) =>
    _isJsLibType('JS', value.type.element);

/// Whether [value] is a `@JSExportName` (internal annotation used in SDK
/// instead of `@JS` from `package:js`).
bool isJSExportNameAnnotation(DartObjectImpl value) {
  var e = value?.type?.element;
  if (e?.name != 'JSExportName') return false;
  var uri = e.source.uri;
  return uri.scheme == 'dart' && uri.path == '_foreign_helper';
}

bool isJsPeerInterface(DartObjectImpl value) =>
    value.type.name == 'JsPeerInterface';
