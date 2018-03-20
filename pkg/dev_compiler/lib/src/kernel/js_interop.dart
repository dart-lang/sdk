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
  var scheme = uri.scheme;
  return scheme == 'package' && uri.pathSegments[0] == 'js' ||
      scheme == 'dart' &&
          (uri.path == '_js_helper' || uri.path == '_foreign_helper');
}

bool _annotationIsFromJSLibrary(String expectedName, Expression value) {
  Class c;
  if (value is ConstructorInvocation) {
    c = value.target.enclosingClass;
  } else if (value is StaticGet) {
    var type = value.target.getterType;
    if (type is InterfaceType) c = type.classNode;
  }
  return c != null &&
      c.name == expectedName &&
      _isJSLibrary(c.enclosingLibrary);
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

bool _isJSAnonymousAnnotation(Expression value) =>
    _annotationIsFromJSLibrary('_Anonymous', value);

bool _isBuiltinAnnotation(
    Expression value, String libraryName, String annotationName) {
  if (value is ConstructorInvocation) {
    var c = value.target.enclosingClass;
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

bool isJSAnonymousType(Class namedClass) {
  return hasJSInteropAnnotation(namedClass) &&
      findAnnotation(namedClass, _isJSAnonymousAnnotation) != null;
}

/// Returns true iff the class has an `@JS(...)` annotation from `package:js`.
///
/// Note: usually [_usesJSInterop] should be used instead of this.
//
// TODO(jmesserly): I think almost all uses of this should be replaced with
// [_usesJSInterop], which also checks that the library is marked with `@JS`.
//
// Right now we have inconsistencies: sometimes we'll respect `@JS` on the
// class itself, other places we require it on the library. Also members are
// inconsistent: sometimes they need to have `@JS` on them, other times they
// need to be `external` in an `@JS` class.
bool hasJSInteropAnnotation(Class c) => c.annotations.any(isPublicJSAnnotation);

/// Returns true iff this element is a JS interop member.
///
/// The element's library must have `@JS(...)` annotation from `package:js`.
/// If the element is a class, it must also be marked with `@JS`. Other
/// elements, such as class members and top-level functions/accessors, should
/// be marked `external`.
bool usesJSInterop(NamedNode n) {
  var library = getLibrary(n);
  return library != null &&
      library.annotations.any(isPublicJSAnnotation) &&
      (n is Procedure && n.isExternal ||
          n is Class && n.annotations.any(isPublicJSAnnotation));
}

/// Returns the name value of the `JSExportName` annotation (when compiling
/// the SDK), or `null` if there's none. This is used to control the name
/// under which functions are compiled and exported.
String getJSExportName(NamedNode n) {
  var library = getLibrary(n);
  if (library == null || library.importUri.scheme != 'dart') return null;

  return getAnnotationName(n, isJSExportNameAnnotation);
}
