// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/dart/element/element.dart';

import 'element_helpers.dart';

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
// TODO(jacobr): The 'JS' annotation is the new, publically accessible one.
// The 'JsName' annotation is the old one using internally by dart2js and
// html libraries.  These two concepts will probably merge eventually.
bool isJSAnnotation(DartObjectImpl value) =>
    _isJsLibType('JS', value.type.element) || isJsName(value);

/// Returns [true] if [e] is the `JS` annotation from `package:js`.
bool isPublicJSAnnotation(DartObjectImpl value) =>
    _isJsLibType('JS', value.type.element);

bool isJSAnonymousAnnotation(DartObjectImpl value) =>
    _isJsLibType('_Anonymous', value.type.element);

bool _isBuiltinAnnotation(
    DartObjectImpl value, String libraryName, String annotationName) {
  var e = value?.type?.element;
  if (e?.name != annotationName) return false;
  var uri = e.source.uri;
  var path = uri.pathSegments[0];
  return uri.scheme == 'dart' && path == libraryName;
}

/// Whether [value] is a `@JSExportName` (internal annotation used in SDK
/// instead of `@JS` from `package:js`).
bool isJSExportNameAnnotation(DartObjectImpl value) =>
    _isBuiltinAnnotation(value, '_foreign_helper', 'JSExportName');

bool isJsName(DartObjectImpl value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'JSName');

bool isJsPeerInterface(DartObjectImpl value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'JsPeerInterface');

bool isNativeAnnotation(DartObjectImpl value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'Native');

/// Returns the name value of the `JSExportName` annotation (when compiling
/// the SDK), or `null` if there's none. This is used to control the name
/// under which functions are compiled and exported.
String getJSExportName(Element e) {
  if (!e.source.isInSystemLibrary) return null;

  e = e is PropertyAccessorElement && e.isSynthetic ? e.variable : e;
  return getAnnotationName(e, isJSExportNameAnnotation);
}
