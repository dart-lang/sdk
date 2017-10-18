// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'kernel_helpers.dart';

/// Returns true if [library] represents any library from `package:js` or is the
/// internal `dart:_js_helper` library.
bool _isJSLibrary(Library library) {
  if (library == null) return false;
  var uri = library.importUri;
  if (uri.scheme == 'package' && uri.path.startsWith('js/')) return true;
  if (uri.scheme == 'dart') {
    return uri.path == '_js_helper' || uri.path == '_foreign_helper';
  }
  return false;
}

bool _annotationIsFromJSLibrary(String expectedName, Expression value) {
  if (value is ConstructorInvocation) {
    var c = value.constructedType.classNode;
    return c.name == expectedName && _isJSLibrary(getLibrary(c));
  }
  return false;
}

/// Whether [value] is a `@rest` annotation (to be used on function parameters
/// to have them compiled as `...` rest params in ES6 outputs).
bool isJsRestAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Rest', value);

// TODO(jmesserly): Move JsPeerInterface to package:js (see issue #135).
// TODO(jacobr): The 'JS' annotation is the new, publically accessible one.
// The 'JsName' annotation is the old one using internally by dart2js and
// html libraries.  These two concepts will probably merge eventually.
bool isJSAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value) || isJSName(value);

/// Returns [true] if [e] is the `JS` annotation from `package:js`.
bool isPublicJSAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('JS', value);

bool isJSAnonymousAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Anonymous', value);

bool _isBuiltinAnnotation(
    Expression value, String libraryName, String annotationName) {
  if (value is ConstructorInvocation) {
    var c = value.constructedType.classNode;
    if (c.name == annotationName) {
      var uri = c.enclosingLibrary.importUri;
      return uri.scheme == 'dart' && uri.pathSegments[0] == libraryName;
    }
  }
  return false;
}

/// Whether [value] is a `@JSExportName` (internal annotation used in SDK
/// instead of `@JS` from `package:js`).
bool isJSExportNameAnnotation(Expression value) =>
    _isBuiltinAnnotation(value, '_foreign_helper', 'JSExportName');

/// Whether [i] is a `spread` invocation (to be used on function arguments
/// to have them compiled as `...` spread args in ES6 outputs).
bool isJSSpreadInvocation(Procedure target) =>
    target.name.name == 'spread' && _isJSLibrary(target.enclosingLibrary);

bool isJSName(Expression value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'JSName');

bool isJsPeerInterface(Expression value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'JsPeerInterface');

bool isNativeAnnotation(Expression value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'Native');

bool isNotNullAnnotation(Expression value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'NotNull');

bool isNullCheckAnnotation(Expression value) =>
    _isBuiltinAnnotation(value, '_js_helper', 'NullCheck');

bool isJSAnonymousType(Class namedClass) {
  return _isJSNative(namedClass) &&
      findAnnotation(namedClass, isJSAnonymousAnnotation) != null;
}

bool isJSReference(NamedNode n) {
  var library = getLibrary(n);
  return library != null &&
      _isJSNative(library) &&
      (n is Procedure && n.isExternal || n is Class && _isJSNative(n));
}

bool _isJSNative(NamedNode n) =>
    findAnnotation(n, isPublicJSAnnotation) != null;

/// Returns the name value of the `JSExportName` annotation (when compiling
/// the SDK), or `null` if there's none. This is used to control the name
/// under which functions are compiled and exported.
String getJSExportName(NamedNode n) {
  var library = getLibrary(n);
  if (library == null || library.importUri.scheme != 'dart') return null;

  return getAnnotationName(n, isJSExportNameAnnotation);
}
